import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_background_location_models.dart';

enum DriverBackgroundLocationPolicySource { demo, api }

class DriverBackgroundLocationPolicyResult {
  final DriverBackgroundLocationPolicy? policy;
  final String? errorMessage;

  const DriverBackgroundLocationPolicyResult._({
    this.policy,
    this.errorMessage,
  });

  const DriverBackgroundLocationPolicyResult.success(
    DriverBackgroundLocationPolicy value,
  ) : this._(policy: value);

  const DriverBackgroundLocationPolicyResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => policy != null;
}

abstract interface class DriverBackgroundLocationPolicyRepository {
  DriverBackgroundLocationPolicySource get source;

  Future<DriverBackgroundLocationPolicyResult> loadPolicy();
}

class DemoDriverBackgroundLocationPolicyRepository
    implements DriverBackgroundLocationPolicyRepository {
  const DemoDriverBackgroundLocationPolicyRepository();

  @override
  DriverBackgroundLocationPolicySource get source =>
      DriverBackgroundLocationPolicySource.demo;

  @override
  Future<DriverBackgroundLocationPolicyResult> loadPolicy() async {
    return const DriverBackgroundLocationPolicyResult.success(
      DriverBackgroundLocationPolicy(
        version: 'demo-bg-location-v1',
        trackWhenOnline: true,
        trackDuringActiveDelivery: true,
        onlineInterval: Duration(seconds: 30),
        onlineDistanceFilterMeters: 25,
        activeDeliveryInterval: Duration(seconds: 10),
        activeDeliveryDistanceFilterMeters: 10,
      ),
    );
  }
}

class UnavailableDriverBackgroundLocationPolicyRepository
    implements DriverBackgroundLocationPolicyRepository {
  const UnavailableDriverBackgroundLocationPolicyRepository();

  @override
  DriverBackgroundLocationPolicySource get source =>
      DriverBackgroundLocationPolicySource.api;

  @override
  Future<DriverBackgroundLocationPolicyResult> loadPolicy() async {
    return const DriverBackgroundLocationPolicyResult.failure(
      'Background location policy is waiting for the Laravel driver API.',
    );
  }
}

class DriverBackgroundLocationPolicyRepositoryFactory {
  const DriverBackgroundLocationPolicyRepositoryFactory._();

  static DriverBackgroundLocationPolicyRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverBackgroundLocationPolicyRepository()
        : const UnavailableDriverBackgroundLocationPolicyRepository();
  }
}
