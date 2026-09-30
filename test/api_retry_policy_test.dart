import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';
import 'package:getin_driver/core/network/api_retry_policy.dart';
import 'package:getin_driver/core/network/api_transport.dart';

class _SequenceTransport implements ApiTransport {
  final List<ApiRawResponse> responses;
  int calls = 0;

  _SequenceTransport(this.responses);

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    final index = calls++;
    return responses[index < responses.length ? index : responses.length - 1];
  }
}

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://example.test/api',
  );

  test('safe GET retries transient server failures', () async {
    final transport = _SequenceTransport(<ApiRawResponse>[
      const ApiRawResponse(statusCode: 503, body: '{"message":"Busy"}'),
      const ApiRawResponse(statusCode: 200, body: '{"success":true}'),
    ]);
    final client = ApiClient(
      config,
      transport: transport,
      retryPolicy:
          const ApiRetryPolicy(maxAttempts: 2, baseDelay: Duration.zero),
    );

    final result = await client.getJson('/v1/system/config');
    expect(result['success'], isTrue);
    expect(transport.calls, 2);
  });

  test('POST is not retried unless caller explicitly marks it retryable',
      () async {
    final transport = _SequenceTransport(<ApiRawResponse>[
      const ApiRawResponse(statusCode: 503, body: '{"message":"Busy"}'),
      const ApiRawResponse(statusCode: 200, body: '{"success":true}'),
    ]);
    final client = ApiClient(
      config,
      transport: transport,
      retryPolicy:
          const ApiRetryPolicy(maxAttempts: 2, baseDelay: Duration.zero),
    );

    await expectLater(
      client.postJson('/v1/driver/orders'),
      throwsException,
    );
    expect(transport.calls, 1);
  });
}
