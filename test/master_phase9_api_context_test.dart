import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';

class _RecordingTransport implements ApiTransport {
  String? method;
  Map<String, String>? headers;
  Uri? uri;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    this.uri = uri;
    this.method = method;
    this.headers = headers;
    return const ApiRawResponse(
      statusCode: 200,
      body: '{"success":true,"data":{"ok":true}}',
    );
  }
}

void main() {
  test('Phase 9 Driver API context uses secure bearer token and JSON verbs',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final secureStore = MemorySecureStore();
    await secureStore.write(SecureStoreKeys.accessToken, 'driver-token');
    final transport = _RecordingTransport();
    final context = DriverApiContext.create(
      config,
      secureStore: secureStore,
      transport: transport,
    );

    await context.apiClient.deleteJson(
      '/v1/driver/sessions/12',
      authenticated: true,
    );

    expect(context.usesApi, isTrue);
    expect(transport.method, 'DELETE');
    expect(transport.headers?['Authorization'], 'Bearer driver-token');
    expect(transport.uri.toString(),
        'https://example.test/api/v1/driver/sessions/12');
  });
}
