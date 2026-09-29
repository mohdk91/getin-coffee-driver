import '../../home/domain/driver_home_models.dart';

enum DriverAvailabilityChangeStatus { success, blocked, failure }

class DriverAvailabilityChangeResult {
  final DriverAvailabilityChangeStatus status;
  final DriverAvailabilityState state;
  final String message;

  const DriverAvailabilityChangeResult._({
    required this.status,
    required this.state,
    required this.message,
  });

  const DriverAvailabilityChangeResult.success({
    required DriverAvailabilityState state,
    String message = 'Availability updated.',
  }) : this._(
          status: DriverAvailabilityChangeStatus.success,
          state: state,
          message: message,
        );

  const DriverAvailabilityChangeResult.blocked({
    required DriverAvailabilityState state,
    required String message,
  }) : this._(
          status: DriverAvailabilityChangeStatus.blocked,
          state: state,
          message: message,
        );

  const DriverAvailabilityChangeResult.failure({
    required DriverAvailabilityState state,
    required String message,
  }) : this._(
          status: DriverAvailabilityChangeStatus.failure,
          state: state,
          message: message,
        );

  bool get isSuccess => status == DriverAvailabilityChangeStatus.success;
}
