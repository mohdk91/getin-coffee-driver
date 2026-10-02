import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
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

class ApiDriverBackgroundLocationPolicyRepository
    implements DriverBackgroundLocationPolicyRepository {
  final DriverApiContext context;

  const ApiDriverBackgroundLocationPolicyRepository(this.context);

  @override
  DriverBackgroundLocationPolicySource get source =>
      DriverBackgroundLocationPolicySource.api;

  @override
  Future<DriverBackgroundLocationPolicyResult> loadPolicy() async {
    try {
      final data = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/location/policy',
          authenticated: true,
        ),
      );
      final tracking = data['tracking'] is Map
          ? Map<String, dynamic>.from(data['tracking'] as Map)
          : const <String, dynamic>{};

      final backgroundEnabled = tracking['background_enabled'] != false;
      final onlineOnly = tracking['background_online_only'] != false;
      final foregroundSeconds =
          (tracking['foreground_interval_seconds'] as num?)?.toInt() ?? 15;
      final backgroundSeconds =
          (tracking['background_interval_seconds'] as num?)?.toInt() ?? 60;
      final distance = (tracking['min_distance_meters'] as num?)?.toInt() ?? 25;

      return DriverBackgroundLocationPolicyResult.success(
        DriverBackgroundLocationPolicy(
          version: 'laravel-location-policy-v1',
          trackWhenOnline: backgroundEnabled && onlineOnly,
          trackDuringActiveDelivery: backgroundEnabled,
          onlineInterval: Duration(seconds: backgroundSeconds.clamp(5, 3600)),
          onlineDistanceFilterMeters: distance.clamp(0, 5000),
          activeDeliveryInterval:
              Duration(seconds: foregroundSeconds.clamp(5, 3600)),
          activeDeliveryDistanceFilterMeters: distance.clamp(0, 5000),
        ),
      );
    } on ApiException catch (error) {
      return DriverBackgroundLocationPolicyResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverBackgroundLocationPolicyResult.failure(error.message);
    }
  }
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

  static DriverBackgroundLocationPolicyRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const DemoDriverBackgroundLocationPolicyRepository();
    }
    return ApiDriverBackgroundLocationPolicyRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}
