import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_start_delivery_models.dart';

abstract interface class DriverStartDeliveryRepository {
  DriverStartDeliveryDataSource get source;

  Future<DriverStartDeliveryResult> startDelivery({
    required String orderNumber,
    required double? latitude,
    required double? longitude,
  });
}

class DriverStartDeliveryRepositoryFactory {
  DriverStartDeliveryRepositoryFactory._();

  static DriverStartDeliveryRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverStartDeliveryRepository()
        : const UnavailableDriverStartDeliveryRepository();
  }
}

class DemoDriverStartDeliveryRepository
    implements DriverStartDeliveryRepository {
  const DemoDriverStartDeliveryRepository();

  @override
  DriverStartDeliveryDataSource get source =>
      DriverStartDeliveryDataSource.demo;

  @override
  Future<DriverStartDeliveryResult> startDelivery({
    required String orderNumber,
    required double? latitude,
    required double? longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final startedAt = DateTime.now();

    return DriverStartDeliveryResult.success(
      DriverStartDeliveryReceipt(
        auditId: 'DEMO-START-$orderNumber-${startedAt.millisecondsSinceEpoch}',
        orderNumber: orderNumber,
        driverId: 'DEMO-DRIVER-001',
        startedAt: startedAt,
        latitude: latitude,
        longitude: longitude,
        serverAcknowledged: false,
        isDemo: true,
      ),
    );
  }
}

class UnavailableDriverStartDeliveryRepository
    implements DriverStartDeliveryRepository {
  const UnavailableDriverStartDeliveryRepository();

  @override
  DriverStartDeliveryDataSource get source => DriverStartDeliveryDataSource.api;

  @override
  Future<DriverStartDeliveryResult> startDelivery({
    required String orderNumber,
    required double? latitude,
    required double? longitude,
  }) async {
    return const DriverStartDeliveryResult.failure(
      'Could not confirm Start Delivery with Getin. The order remains picked up and its status has not changed.',
    );
  }
}
