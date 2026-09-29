import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test('demo home repository returns an explicit local dashboard snapshot',
      () async {
    const repository = DemoDriverHomeRepository();

    final result = await repository.loadDashboard();

    expect(repository.source, DriverHomeDataSource.demo);
    expect(result.isSuccess, isTrue);
    expect(result.snapshot, isNotNull);
    expect(result.snapshot!.availability, DriverAvailabilityState.online);
    expect(result.snapshot!.activeDelivery, isNotNull);
    expect(result.snapshot!.availableOrders, greaterThanOrEqualTo(0));
    expect(result.snapshot!.completedToday, greaterThanOrEqualTo(0));
    expect(result.snapshot!.internetConnected, isTrue);
    expect(result.snapshot!.gpsState, DriverGpsState.ready);
  });
}
