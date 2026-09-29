import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/availability/data/driver_availability_repository.dart';
import 'package:getin_driver/features/availability/domain/driver_availability_result.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  const repository = DemoDriverAvailabilityRepository();

  test('demo availability can go offline when there is no active delivery',
      () async {
    final result = await repository.changeAvailability(
      currentState: DriverAvailabilityState.online,
      requestedState: DriverAvailabilityState.offline,
      hasActiveDelivery: false,
    );

    expect(repository.source, DriverAvailabilityDataSource.demo);
    expect(result.status, DriverAvailabilityChangeStatus.success);
    expect(result.state, DriverAvailabilityState.offline);
  });

  test('active delivery blocks offline state', () async {
    final result = await repository.changeAvailability(
      currentState: DriverAvailabilityState.online,
      requestedState: DriverAvailabilityState.offline,
      hasActiveDelivery: true,
    );

    expect(result.status, DriverAvailabilityChangeStatus.blocked);
    expect(result.state, DriverAvailabilityState.online);
    expect(result.message, contains('active delivery'));
  });

  test('active delivery can enter break without abandoning the delivery',
      () async {
    final result = await repository.changeAvailability(
      currentState: DriverAvailabilityState.online,
      requestedState: DriverAvailabilityState.onBreak,
      hasActiveDelivery: true,
    );

    expect(result.status, DriverAvailabilityChangeStatus.success);
    expect(result.state, DriverAvailabilityState.onBreak);
  });
}
