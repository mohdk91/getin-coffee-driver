import '../../home/domain/driver_home_models.dart';
import '../domain/driver_availability_result.dart';

enum DriverAvailabilityDataSource { demo, api }

abstract interface class DriverAvailabilityRepository {
  DriverAvailabilityDataSource get source;

  Future<DriverAvailabilityChangeResult> changeAvailability({
    required DriverAvailabilityState currentState,
    required DriverAvailabilityState requestedState,
    required bool hasActiveDelivery,
  });
}

class DemoDriverAvailabilityRepository implements DriverAvailabilityRepository {
  const DemoDriverAvailabilityRepository();

  @override
  DriverAvailabilityDataSource get source => DriverAvailabilityDataSource.demo;

  @override
  Future<DriverAvailabilityChangeResult> changeAvailability({
    required DriverAvailabilityState currentState,
    required DriverAvailabilityState requestedState,
    required bool hasActiveDelivery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (requestedState == currentState) {
      return DriverAvailabilityChangeResult.success(
        state: currentState,
        message: 'Availability is already ${currentState.label}.',
      );
    }

    if (hasActiveDelivery &&
        requestedState == DriverAvailabilityState.offline) {
      return DriverAvailabilityChangeResult.blocked(
        state: currentState,
        message:
            'You cannot go Offline while an active delivery still requires completion.',
      );
    }

    return DriverAvailabilityChangeResult.success(
      state: requestedState,
      message: 'Availability changed to ${requestedState.label}.',
    );
  }
}
