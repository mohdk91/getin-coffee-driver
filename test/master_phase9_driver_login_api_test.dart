import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/driver_token_store.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/auth/data/driver_auth_repository.dart';
import 'package:getin_driver/features/auth/domain/driver_auth_models.dart';

class _LoginTransport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"driver":{"id":7,"name":"Live Driver","account_status":"active","approval_status":"approved","can_operate":true},"token":"live-token","token_type":"Bearer"}}',
    );
  }
}

void main() {
  test('Phase 9 live Driver login maps account and stores Sanctum token',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final store = MemorySecureStore();
    final context = DriverApiContext.create(
      config,
      secureStore: store,
      transport: _LoginTransport(),
    );
    final repository = ApiDriverAuthRepository(context);

    final result = await repository.signInWithEmail(
      email: 'driver@example.com',
      password: 'Driver1234',
    );

    expect(result.isSuccess, isTrue);
    expect(result.data?.displayName, 'Live Driver');
    expect(result.data?.accessState, DriverAccessState.active);
    expect(await DriverTokenStore(store).readAccessToken(), 'live-token');
  });
}
