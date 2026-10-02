import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';
import 'package:getin_driver/core/network/api_exception.dart';
import 'package:getin_driver/core/network/api_retry_policy.dart';
import 'package:getin_driver/core/network/api_transport.dart';

class _RuntimeTransport implements ApiTransport {
  _RuntimeTransport({this.response, this.error});

  final ApiRawResponse? response;
  final Object? error;
  int calls = 0;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    calls++;
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://example.test/api',
  );
  const retry = ApiRetryPolicy(maxAttempts: 3, baseDelay: Duration.zero);

  test('offline GET is classified and retried only by safe request policy', () async {
    final transport = _RuntimeTransport(error: const SocketException('offline'));
    final client = ApiClient(config, transport: transport, retryPolicy: retry);

    await expectLater(
      client.getJson('/v1/customer/profile'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiFailureKind.offline)
            .having((e) => e.isRetryable, 'retryable', isTrue),
      ),
    );
    expect(transport.calls, 3);
  });

  test('timeout is classified without exposing the raw transport failure', () async {
    final transport = _RuntimeTransport(error: TimeoutException('socket detail'));
    final client = ApiClient(config, transport: transport, retryPolicy: retry);

    await expectLater(
      client.getJson('/v1/customer/profile'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiFailureKind.timeout)
            .having((e) => e.message.contains('socket detail'), 'safe message', isFalse),
      ),
    );
  });

  test('409 is a non-retryable conflict and POST is not replayed', () async {
    final transport = _RuntimeTransport(
      response: const ApiRawResponse(
        statusCode: 409,
        body: '{"success":false,"message":"Order state changed."}',
      ),
    );
    final client = ApiClient(config, transport: transport, retryPolicy: retry);

    await expectLater(
      client.postJson('/v1/customer/orders'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiFailureKind.conflict)
            .having((e) => e.isRetryable, 'retryable', isFalse),
      ),
    );
    expect(transport.calls, 1);
  });

  test('429 exposes rate-limit retry metadata after safe retries are exhausted', () async {
    final transport = _RuntimeTransport(
      response: const ApiRawResponse(
        statusCode: 429,
        body: '{"success":false,"message":"Too many requests."}',
        headers: {'Retry-After': '7'},
      ),
    );
    final client = ApiClient(config, transport: transport, retryPolicy: retry);

    await expectLater(
      client.getJson('/v1/customer/orders'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiFailureKind.rateLimited)
            .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 7)),
      ),
    );
    expect(transport.calls, 3);
  });

  test('invalid JSON has its own failure classification', () async {
    final transport = _RuntimeTransport(
      response: const ApiRawResponse(statusCode: 200, body: '<html>bad gateway</html>'),
    );
    final client = ApiClient(config, transport: transport, retryPolicy: retry);

    await expectLater(
      client.getJson('/v1/system/config'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.invalidResponse,
        ),
      ),
    );
  });
}
