import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_retry_policy.dart';
import 'api_transport.dart';

typedef AccessTokenProvider = Future<String?> Function();

class ApiClient {
  final AppConfig config;
  final ApiTransport? transport;
  final AccessTokenProvider? tokenProvider;
  final ApiRetryPolicy retryPolicy;

  const ApiClient(
    this.config, {
    this.transport,
    this.tokenProvider,
    this.retryPolicy = const ApiRetryPolicy(),
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
      if (value != null) {
        queryParameters[entry.key] = value.toString();
      }
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
    bool retryable = false,
  }) {
    return requestJson(
      'POST',
      path,
      query: query,
      body: body,
      authenticated: authenticated,
      retryable: retryable,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
    bool authenticated = false,
    bool retryable = false,
  }) {
    return requestJson(
      'PUT',
      path,
      query: query,
      body: body,
      authenticated: authenticated,
      retryable: retryable,
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
    bool authenticated = false,
    bool retryable = false,
  }) {
    return requestJson(
      'PATCH',
      path,
      query: query,
      body: body,
      authenticated: authenticated,
      retryable: retryable,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
    bool authenticated = false,
    bool retryable = false,
  }) {
    return requestJson(
      'DELETE',
      path,
      query: query,
      body: body,
      authenticated: authenticated,
      retryable: retryable,
    );
  }

  Future<Map<String, dynamic>> postMultipartFile(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, String> fields = const {},
    bool authenticated = false,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const ApiException('Selected document file is unavailable.');
    }
    final boundary = 'getin-${DateTime.now().microsecondsSinceEpoch}';
    final request = await HttpClient().postUrl(endpoint(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary');
    if (authenticated) {
      final token = await tokenProvider?.call();
      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          'Authentication token is unavailable.',
          statusCode: 401,
        );
      }
      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer ${token.trim()}');
    }
    for (final entry in fields.entries) {
      request.write(
          '--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n');
    }
    final name =
        file.uri.pathSegments.isEmpty ? 'document' : file.uri.pathSegments.last;
    request.write(
        '--$boundary\r\nContent-Disposition: form-data; name="$fileField"; filename="$name"\r\nContent-Type: ${_mimeFor(name)}\r\n\r\n');
    request.add(await file.readAsBytes());
    request.write('\r\n--$boundary--\r\n');
    final response = await request.close().timeout(config.requestTimeout);
    final body = await utf8.decoder.bind(response).join();
    return _decode(ApiRawResponse(statusCode: response.statusCode, body: body));
  }

  String _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> requestJson(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool authenticated = false,
    Map<String, String> headers = const {},
    bool? retryable,
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

    final canRetry = retryable ?? _methodIsSafeToRetry(method);
    final attempts = canRetry ? retryPolicy.maxAttempts : 1;
    Object? lastTransportError;

    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final response = await (transport ?? const IoApiTransport()).send(
          endpoint(path, query: query),
          method: method.toUpperCase(),
          headers: requestHeaders,
          body: body,
          timeout: config.requestTimeout,
        );

        if (canRetry &&
            attempt < attempts &&
            retryPolicy.shouldRetryStatus(response.statusCode)) {
          await _delayBeforeRetry(attempt + 1);
          continue;
        }

        return _decode(response);
      } catch (error) {
        if (error is ApiException) {
          rethrow;
        }
        lastTransportError = error;

        if (!canRetry || attempt >= attempts) {
          break;
        }

        await _delayBeforeRetry(attempt + 1);
      }
    }

    throw ApiException(
      'Unable to reach the GETIN API.',
      cause: lastTransportError,
    );
  }

  bool _methodIsSafeToRetry(String method) {
    return const <String>{'GET', 'HEAD', 'OPTIONS'}
        .contains(method.toUpperCase());
  }

  Future<void> _delayBeforeRetry(int nextAttempt) async {
    final delay = retryPolicy.delayBeforeAttempt(nextAttempt);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
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
