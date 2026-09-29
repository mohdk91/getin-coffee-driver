import '../domain/driver_location_models.dart';
import '../../home/domain/driver_home_models.dart';

enum DriverLocationDataSource { demo, api }

class DriverLocationLoadResult {
  final DriverServiceRegionProfile? profile;
  final String? errorMessage;

  const DriverLocationLoadResult._({this.profile, this.errorMessage});

  const DriverLocationLoadResult.success(DriverServiceRegionProfile profile)
      : this._(profile: profile);

  const DriverLocationLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => profile != null;
}

abstract interface class DriverLocationRepository {
  DriverLocationDataSource get source;

  Future<DriverLocationLoadResult> loadLocationProfile();
}

class DemoDriverLocationRepository implements DriverLocationRepository {
  const DemoDriverLocationRepository();

  @override
  DriverLocationDataSource get source => DriverLocationDataSource.demo;

  @override
  Future<DriverLocationLoadResult> loadLocationProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    return DriverLocationLoadResult.success(
      DriverServiceRegionProfile(
        country: 'Egypt',
        city: 'Alexandria',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        allowedBranches: const ['Stanley', 'Gleem'],
        deliveryRadiusKm: 8,
        vehicleType: 'Motorbike',
        currentGps: DriverGpsFix(
          coordinates: const DriverCoordinates(
            latitude: 31.24580,
            longitude: 29.96680,
          ),
          accuracyMeters: 12,
          capturedAt: DateTime.now(),
          state: DriverGpsState.ready,
        ),
      ),
    );
  }
}

class UnavailableDriverLocationRepository implements DriverLocationRepository {
  const UnavailableDriverLocationRepository();

  @override
  DriverLocationDataSource get source => DriverLocationDataSource.api;

  @override
  Future<DriverLocationLoadResult> loadLocationProfile() async {
    return const DriverLocationLoadResult.failure(
      'Driver location and service-region API are not connected yet. No demo GPS is shown outside development.',
    );
  }
}
