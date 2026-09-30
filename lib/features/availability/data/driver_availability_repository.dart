import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
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

class DriverAvailabilityRepositoryFactory {
  DriverAvailabilityRepositoryFactory._();

  static DriverAvailabilityRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverAvailabilityRepository();
    }
    return ApiDriverAvailabilityRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverAvailabilityRepository implements DriverAvailabilityRepository {
  final DriverApiContext context;

  const ApiDriverAvailabilityRepository(this.context);

  @override
  DriverAvailabilityDataSource get source => DriverAvailabilityDataSource.api;

  @override
  Future<DriverAvailabilityChangeResult> changeAvailability({
    required DriverAvailabilityState currentState,
    required DriverAvailabilityState requestedState,
    required bool hasActiveDelivery,
  }) async {
    try {
      final envelope = await context.apiClient.putJson(
        '/v1/driver/availability',
        authenticated: true,
        body: <String, Object?>{'status': _wire(requestedState)},
      );
      final data = DriverApiContext.dataMap(envelope);
      final state = _state(data['status']?.toString()) ?? requestedState;
      return DriverAvailabilityChangeResult.success(
        state: state,
        message: envelope['message']?.toString() ?? 'Availability updated.',
      );
    } on ApiException catch (error) {
      final blocked = error.statusCode == 409 || error.statusCode == 422;
      return blocked
          ? DriverAvailabilityChangeResult.blocked(
              state: currentState,
              message: error.message,
            )
          : DriverAvailabilityChangeResult.failure(
              state: currentState,
              message: error.message,
            );
    }
  }

  static String _wire(DriverAvailabilityState state) => switch (state) {
        DriverAvailabilityState.online => 'online',
        DriverAvailabilityState.offline => 'offline',
        DriverAvailabilityState.onBreak => 'on_break',
      };

  static DriverAvailabilityState? _state(String? value) => switch (value) {
        'online' => DriverAvailabilityState.online,
        'offline' => DriverAvailabilityState.offline,
        'on_break' => DriverAvailabilityState.onBreak,
        _ => null,
      };
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
