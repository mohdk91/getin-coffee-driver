import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../domain/driver_location_models.dart';

abstract interface class DriverLocationSyncRepository {
  Future<void> sync(DriverGpsFix fix);
}

class ApiDriverLocationSyncRepository implements DriverLocationSyncRepository {
  final DriverApiContext context;

  const ApiDriverLocationSyncRepository(this.context);

  @override
  Future<void> sync(DriverGpsFix fix) async {
    await context.apiClient.putJson(
      '/v1/driver/location',
      authenticated: true,
      body: <String, Object?>{
        'latitude': fix.coordinates.latitude,
        'longitude': fix.coordinates.longitude,
        'accuracy': fix.accuracyMeters,
        'timestamp': fix.capturedAt.toUtc().toIso8601String(),
      },
    );
  }
}

class NoopDriverLocationSyncRepository implements DriverLocationSyncRepository {
  const NoopDriverLocationSyncRepository();

  @override
  Future<void> sync(DriverGpsFix fix) async {}
}

class DriverLocationSyncRepositoryFactory {
  DriverLocationSyncRepositoryFactory._();

  static DriverLocationSyncRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const NoopDriverLocationSyncRepository();
    }
    return ApiDriverLocationSyncRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}
