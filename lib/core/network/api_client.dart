import 'dart:convert';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_transport.dart';

typedef AccessTokenProvider = Future<String?> Function();

class ApiClient {
  final AppConfig config;
  final ApiTransport? transport;
  final AccessTokenProvider? tokenProvider;

  const ApiClient(
    this.config, {
    this.transport,
    this.tokenProvider,
  });

  Uri endpoint(String path, {Map<String, Object?> query = const {}}) {
    if (!config.isApiConfigured) {
      throw StateError(
        'API_BASE_URL is not configured. Pass it with --dart-define.',
      );
    }

    final base = config.apiBaseUrl.endsWith('/')
        ? config.apiBaseUrl.substring(0, config.apiBaseUrl.length - 1)
        : config.apiBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$cleanPath');
    final queryParameters = <String, String>{};

    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null) queryParameters[entry.key] = value.toString();
    }

    return queryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?> query = const {},
    bool authenticated = false,
  }) {
    return requestJson(
      'GET',
      path,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
    bool authenticated = false,
  }) {
    return requestJson(
      'POST',
      path,
      query: query,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> requestJson(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool authenticated = false,
    Map<String, String> headers = const {},
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...headers,
    };

    if (authenticated) {
      final token = await tokenProvider?.call();
      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          'Authentication token is unavailable.',
          statusCode: 401,
        );
      }
      requestHeaders['Authorization'] = 'Bearer ${token.trim()}';
    }

    ApiRawResponse response;
    try {
      response = await (transport ?? const IoApiTransport()).send(
        endpoint(path, query: query),
        method: method.toUpperCase(),
        headers: requestHeaders,
        body: body,
        timeout: config.requestTimeout,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        'Unable to reach the GETIN API.',
        cause: error,
      );
    }

    return _decode(response);
  }

  Map<String, dynamic> _decode(ApiRawResponse response) {
    Map<String, dynamic> payload = const <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        } else {
          throw const FormatException('JSON root is not an object.');
        }
      } catch (error) {
        throw ApiException(
          'The GETIN API returned an invalid JSON response.',
          statusCode: response.statusCode,
          cause: error,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawErrors = payload['errors'];
      throw ApiException(
        payload['message']?.toString() ?? 'The GETIN API request failed.',
        statusCode: response.statusCode,
        errors: rawErrors is Map
            ? Map<String, dynamic>.from(rawErrors)
            : const <String, dynamic>{},
      );
    }

    return payload;
  }
}
