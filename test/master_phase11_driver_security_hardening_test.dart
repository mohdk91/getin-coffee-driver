import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/security/data/driver_security_repository.dart';

class _FailingLogoutTransport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    return const ApiRawResponse(
      statusCode: 503,
      body: '{"success":false,"message":"Server unavailable"}',
    );
  }
}

void main() {
  test('Task 132 logout clears local access token even if server revoke fails',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'driver-token');
    final repo = ApiDriverSecurityRepository(
      DriverApiContext.create(
        config,
        secureStore: store,
        transport: _FailingLogoutTransport(),
      ),
    );

    final result = await repo.logout();

    expect(result.success, isTrue);
    expect(await store.read(SecureStoreKeys.accessToken), isNull);
    expect(result.message, contains('Signed out on this device'));
  });

  test('Task 132 configured production factory always uses API security', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    expect(
      DriverSecurityRepositoryFactory.create(config),
      isA<ApiDriverSecurityRepository>(),
    );
  });
}
