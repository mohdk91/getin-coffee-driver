import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_policy_repository.dart';
import 'package:getin_driver/features/location/data/driver_location_sync_repository.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
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
  final List<String> methods = <String>[];
  final List<String> paths = <String>[];

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    methods.add(method);
    paths.add(uri.path);
    if (uri.path.endsWith('/policy')) {
      return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"tracking":{"background_enabled":true,"background_online_only":true,"foreground_interval_seconds":10,"background_interval_seconds":60,"min_distance_meters":25}}}',
      );
    }
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"latitude":31.2,"longitude":29.9,"accuracy":8,"timestamp":"2026-10-01T00:00:00Z"}}',
    );
  }
}

void main() {
  test('Task 104 loads server policy and syncs GPS through Laravel', () async {
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
    final policy = ApiDriverBackgroundLocationPolicyRepository(context);
    final result = await policy.loadPolicy();
    expect(result.policy?.trackDuringActiveDelivery, isTrue);
    expect(result.policy?.onlineInterval, const Duration(seconds: 60));

    final sync = ApiDriverLocationSyncRepository(context);
    await sync.sync(
      DriverGpsFix(
        coordinates: const DriverCoordinates(latitude: 31.2, longitude: 29.9),
        accuracyMeters: 8,
        capturedAt: DateTime.utc(2026, 10, 1),
        state: DriverGpsState.ready,
      ),
    );
    expect(transport.methods, contains('PUT'));
    expect(transport.paths, contains('/api/v1/driver/location'));
  });
}
