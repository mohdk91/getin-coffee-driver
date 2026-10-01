import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/location/data/driver_location_repository.dart';

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
  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    if (uri.path.endsWith('/location')) {
      return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"latitude":31.2,"longitude":29.9,"accuracy":12,"timestamp":"2026-10-01T00:00:00+00:00"}}',
      );
    }
    if (uri.path.endsWith('/assignments')) {
      return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"branches":[{"name":"Stanley","city":"Alexandria","country_code":"EG","is_primary":true}],"regions":[{"name":"East Alexandria","city":"Alexandria","country_code":"EG","radius_km":8,"is_primary":true}]}}',
      );
    }
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"items":[{"vehicle_type":"motorbike","is_primary":true}]}}',
    );
  }
}

void main() {
  test('Task 103 production location maps Laravel GPS and assignment context',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final repository = DriverLocationRepositoryFactory.create(
      config,
      context: DriverApiContext.create(
        config,
        secureStore: _AuthenticatedStore(),
        transport: _Transport(),
      ),
    );
    final result = await repository.loadLocationProfile();

    expect(repository.source, DriverLocationDataSource.api);
    expect(result.isSuccess, isTrue);
    expect(result.profile?.city, 'Alexandria');
    expect(result.profile?.currentGps.accuracyMeters, 12);
  });
}
