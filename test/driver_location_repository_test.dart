import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/data/driver_location_repository.dart';

void main() {
  test('demo location repository exposes Task 8 assignment and GPS data',
      () async {
    const repository = DemoDriverLocationRepository();

    final result = await repository.loadLocationProfile();

    expect(repository.source, DriverLocationDataSource.demo);
    expect(result.isSuccess, isTrue);
    expect(result.profile, isNotNull);
    expect(result.profile!.country, 'Egypt');
    expect(result.profile!.city, 'Alexandria');
    expect(result.profile!.region, contains('Stanley'));
    expect(result.profile!.allowedBranches, containsAll(['Stanley', 'Gleem']));
    expect(result.profile!.deliveryRadiusKm, 8);
    expect(result.profile!.vehicleType, 'Motorbike');
    expect(result.profile!.currentGps.state, DriverGpsState.ready);
    expect(result.profile!.currentGps.accuracyMeters, greaterThan(0));
  });

  test('API location repository does not fake a GPS profile', () async {
    const repository = UnavailableDriverLocationRepository();

    final result = await repository.loadLocationProfile();

    expect(repository.source, DriverLocationDataSource.api);
    expect(result.isSuccess, isFalse);
    expect(result.profile, isNull);
    expect(result.errorMessage, contains('not connected'));
  });
}
