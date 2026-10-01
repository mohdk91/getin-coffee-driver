import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_start_delivery_models.dart';

abstract interface class DriverStartDeliveryRepository {
  DriverStartDeliveryDataSource get source;

  Future<DriverStartDeliveryResult> startDelivery({
    required int? apiOrderId,
    required String orderNumber,
    required double? latitude,
    required double? longitude,
  });
}

class DriverStartDeliveryRepositoryFactory {
  DriverStartDeliveryRepositoryFactory._();

  static DriverStartDeliveryRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverStartDeliveryRepository();
    }
    return ApiDriverStartDeliveryRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverStartDeliveryRepository
    implements DriverStartDeliveryRepository {
  final DriverApiContext context;

  const ApiDriverStartDeliveryRepository(this.context);

  @override
  DriverStartDeliveryDataSource get source => DriverStartDeliveryDataSource.api;

  @override
  Future<DriverStartDeliveryResult> startDelivery({
    required int? apiOrderId,
    required String orderNumber,
    required double? latitude,
    required double? longitude,
  }) async {
    if (apiOrderId == null) {
      return const DriverStartDeliveryResult.failure(
        'The active delivery is missing its Laravel order identifier.',
      );
    }
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/start-delivery',
        authenticated: true,
        headers: <String, String>{
          'Idempotency-Key': 'driver-start-delivery-$apiOrderId',
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final startedAt = DateTime.tryParse(
            data['delivery_state_changed_at']?.toString() ?? '',
          ) ??
          DateTime.now();
      return DriverStartDeliveryResult.success(
        DriverStartDeliveryReceipt(
          auditId: 'start-$apiOrderId-${startedAt.millisecondsSinceEpoch}',
          orderNumber: data['order_number']?.toString() ?? orderNumber,
          driverId: 'server-authenticated-driver',
          startedAt: startedAt,
          latitude: latitude,
          longitude: longitude,
          serverAcknowledged: true,
          isDemo: false,
        ),
      );
    } on ApiException catch (error) {
      return DriverStartDeliveryResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverStartDeliveryResult.failure(error.message);
    }
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
    required int? apiOrderId,
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
  Future<DriverStartDeliveryResult> startDelivery(
          {required int? apiOrderId,
          required String orderNumber,
          required double? latitude,
          required double? longitude}) async =>
      const DriverStartDeliveryResult.failure(
          'Could not confirm Start Delivery with Getin.');
}
