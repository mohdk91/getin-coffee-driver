import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/availability/data/driver_availability_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

class _AuthenticatedStore extends MemorySecureStore {
  @override
  Future<String?> read(String key) async {
    if (key == SecureStoreKeys.accessToken) {
      return 'phase10-driver-token';
    }
    return super.read(key);
  }
}

class _Transport implements ApiTransport {
  String? method;
  Uri? uri;
  Object? body;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    this.method = method;
    this.uri = uri;
    this.body = body;
    return const ApiRawResponse(
      statusCode: 200,
      body: '{"success":true,"data":{"status":"on_break"}}',
    );
  }
}

void main() {
  test('Task 101 production availability is server acknowledged', () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final transport = _Transport();
    final context = DriverApiContext.create(
      config,
      secureStore: _AuthenticatedStore(),
      transport: transport,
    );
    final repository = DriverAvailabilityRepositoryFactory.create(
      config,
      context: context,
    );

    final result = await repository.changeAvailability(
      currentState: DriverAvailabilityState.online,
      requestedState: DriverAvailabilityState.onBreak,
      hasActiveDelivery: false,
    );

    expect(repository.source, DriverAvailabilityDataSource.api);
    expect(result.isSuccess, isTrue);
    expect(result.state, DriverAvailabilityState.onBreak);
    expect(transport.method, 'PUT');
    expect(transport.uri?.path, '/api/v1/driver/availability');
  });
}
