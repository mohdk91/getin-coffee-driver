import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';
import 'package:getin_driver/core/network/api_exception.dart';
import 'package:getin_driver/core/network/api_retry_policy.dart';
import 'package:getin_driver/core/network/api_transport.dart';

class _ObservingTransport implements ApiTransport {
  final List<ApiRawResponse> responses;
  final List<Map<String, String>> headers = <Map<String, String>>[];
  int calls = 0;

  _ObservingTransport(this.responses);

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    this.headers.add(Map<String, String>.from(headers));
    final index = calls++;
    return responses[index < responses.length ? index : responses.length - 1];
  }
}

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://example.test/api',
  );

  test('Task 241 sends one stable request id across safe retries', () async {
    final transport = _ObservingTransport(<ApiRawResponse>[
      const ApiRawResponse(statusCode: 503, body: '{"message":"Busy"}'),
      const ApiRawResponse(statusCode: 200, body: '{"success":true}'),
    ]);
    final client = ApiClient(
      config,
      transport: transport,
      requestIdProvider: () => 'driver-task241-req-001',
      retryPolicy: const ApiRetryPolicy(maxAttempts: 2, baseDelay: Duration.zero),
    );

    await client.getJson('/v1/system/config');

    expect(transport.calls, 2);
    expect(transport.headers[0]['X-Request-ID'], 'driver-task241-req-001');
    expect(transport.headers[1]['X-Request-ID'], 'driver-task241-req-001');
  });

  test('Task 241 exposes server correlation id on normalized failures', () async {
    final transport = _ObservingTransport(<ApiRawResponse>[
      const ApiRawResponse(
        statusCode: 500,
        body: '{"success":false,"message":"An unexpected server error occurred."}',
        headers: <String, String>{'x-request-id': 'server-task241-req-002'},
      ),
    ]);
    final client = ApiClient(
      config,
      transport: transport,
      requestIdProvider: () => 'driver-task241-req-002',
      retryPolicy: const ApiRetryPolicy(maxAttempts: 1),
    );

    try {
      await client.getJson('/v1/failure');
      fail('Expected ApiException');
    } on ApiException catch (error) {
      expect(error.requestId, 'server-task241-req-002');
      expect(error.supportReference, 'server-task241-req-002');
      expect(error.toString(), contains('server-task241-req-002'));
      expect(error.toString(), isNot(contains('Authorization')));
    }
  });
}
