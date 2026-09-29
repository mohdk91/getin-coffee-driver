import 'dart:convert';
import 'dart:io';

class ApiRawResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  const ApiRawResponse({
    required this.statusCode,
    required this.body,
    this.headers = const <String, String>{},
  });
}

abstract class ApiTransport {
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  });
}

class IoApiTransport implements ApiTransport {
  const IoApiTransport();

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final request = await client.openUrl(method, uri).timeout(timeout);
      headers.forEach(request.headers.set);

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      final responseBody =
          await utf8.decoder.bind(response).join().timeout(timeout);
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });

      return ApiRawResponse(
        statusCode: response.statusCode,
        body: responseBody,
        headers: responseHeaders,
      );
    } finally {
      client.close(force: true);
    }
  }
}
