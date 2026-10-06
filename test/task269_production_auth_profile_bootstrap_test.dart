import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/driver_token_store.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/auth/data/driver_session_bootstrap_repository.dart';
import 'package:getin_driver/features/auth/domain/driver_auth_models.dart';

class _ProfileTransport implements ApiTransport {
  int calls = 0;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    calls += 1;
    expect(method, 'GET');
    expect(uri.path, '/api/v1/driver/profile');
    expect(headers['Authorization'], 'Bearer persisted-token');
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"id":44,"name":"Production Driver","account_status":"active","approval_status":"approved","can_operate":true,"assigned_regions":[],"assigned_branches":[]}}',
    );
  }
}

void main() {
  const config = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://example.test/api',
  );

  test('Task 269 restores a persisted production session from Driver profile',
      () async {
    final store = MemorySecureStore();
    await DriverTokenStore(store).saveAccessToken('persisted-token');
    final transport = _ProfileTransport();
    final repository = ApiDriverSessionBootstrapRepository(
      DriverApiContext.create(
        config,
        secureStore: store,
        transport: transport,
      ),
    );

    final result = await repository.restore();

    expect(result.isAuthenticated, isTrue);
    expect(result.account?.driverId, '44');
    expect(result.account?.displayName, 'Production Driver');
    expect(result.account?.accessState, DriverAccessState.active);
    expect(transport.calls, 1);
  });

  test('Task 269 does not call profile when no persisted token exists',
      () async {
    final transport = _ProfileTransport();
    final repository = ApiDriverSessionBootstrapRepository(
      DriverApiContext.create(
        config,
        secureStore: MemorySecureStore(),
        transport: transport,
      ),
    );

    final result = await repository.restore();

    expect(result.isAuthenticated, isFalse);
    expect(result.errorMessage, isNull);
    expect(transport.calls, 0);
  });
}
