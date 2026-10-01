import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../delivery_verification/domain/driver_delivery_pin_models.dart';
import '../domain/driver_delivery_completion_models.dart';

abstract interface class DriverDeliveryCompletionRepository {
  DriverDeliveryCompletionDataSource get source;
  Future<DriverDeliveryCompletionResult> completeDelivery({
    required int? apiOrderId,
    required String orderNumber,
    required DriverDeliveryPinReceipt verification,
  });
}

class DriverDeliveryCompletionRepositoryFactory {
  DriverDeliveryCompletionRepositoryFactory._();
  static DriverDeliveryCompletionRepository create(AppConfig config,
      {DriverApiContext? context}) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverDeliveryCompletionRepository();
    }
    return ApiDriverDeliveryCompletionRepository(
        context ?? DriverApiContext.create(config));
  }
}

class ApiDriverDeliveryCompletionRepository
    implements DriverDeliveryCompletionRepository {
  final DriverApiContext context;
  const ApiDriverDeliveryCompletionRepository(this.context);
  @override
  DriverDeliveryCompletionDataSource get source =>
      DriverDeliveryCompletionDataSource.api;

  @override
  Future<DriverDeliveryCompletionResult> completeDelivery({
    required int? apiOrderId,
    required String orderNumber,
    required DriverDeliveryPinReceipt verification,
  }) async {
    if (apiOrderId == null) {
      return const DriverDeliveryCompletionResult.failure(
        reason: DriverDeliveryCompletionFailureReason.unavailable,
        message: 'The active delivery is missing its Laravel order identifier.',
      );
    }
    if (!deliveryVerificationMatchesOrder(
        verification: verification, orderNumber: orderNumber)) {
      return const DriverDeliveryCompletionResult.failure(
        reason: DriverDeliveryCompletionFailureReason.verificationMismatch,
        message:
            'Delivery verification does not belong to this order. The order status has not changed.',
      );
    }
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/complete-delivery',
        authenticated: true,
        headers: <String, String>{
          'Idempotency-Key': 'driver-complete-$apiOrderId'
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final completedAt =
          DateTime.tryParse(data['completed_at']?.toString() ?? '') ??
              DateTime.now();
      return DriverDeliveryCompletionResult.success(
        value: DriverDeliveryCompletionReceipt(
          auditId: 'server-delivered-$apiOrderId',
          orderNumber: data['order_number']?.toString() ?? orderNumber,
          driverReference: verification.assignedDriverReference,
          completedAt: completedAt,
          serverTimestamp: completedAt,
          latitude: null,
          longitude: null,
          verificationType: verification.verificationType,
          orderState: data['delivery_state']?.toString() ?? 'delivered',
          serverAcknowledged: true,
          isDemo: false,
        ),
        message: envelope['message']?.toString() ??
            'Delivery completed and acknowledged by Getin.',
      );
    } on ApiException catch (error) {
      return DriverDeliveryCompletionResult.failure(
          reason: DriverDeliveryCompletionFailureReason.unavailable,
          message: error.message);
    } on FormatException catch (error) {
      return DriverDeliveryCompletionResult.failure(
          reason: DriverDeliveryCompletionFailureReason.unavailable,
          message: error.message);
    }
  }
}

class DemoDriverDeliveryCompletionRepository
    implements DriverDeliveryCompletionRepository {
  const DemoDriverDeliveryCompletionRepository();
  @override
  DriverDeliveryCompletionDataSource get source =>
      DriverDeliveryCompletionDataSource.demo;
  @override
  Future<DriverDeliveryCompletionResult> completeDelivery(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryPinReceipt verification}) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final normalizedOrder = orderNumber.trim().toUpperCase();
    if (!deliveryVerificationMatchesOrder(
        verification: verification, orderNumber: normalizedOrder)) {
      return const DriverDeliveryCompletionResult.failure(
          reason: DriverDeliveryCompletionFailureReason.verificationMismatch,
          message:
              'Delivery verification does not belong to this order. The order status has not changed.');
    }
    final completedAt = DateTime.now();
    return DriverDeliveryCompletionResult.success(
      value: DriverDeliveryCompletionReceipt(
        auditId:
            'DEMO-DELIVERED-$normalizedOrder-${completedAt.millisecondsSinceEpoch}',
        orderNumber: normalizedOrder,
        driverReference: verification.assignedDriverReference,
        completedAt: completedAt,
        serverTimestamp: null,
        latitude: 31.24580,
        longitude: 29.96680,
        verificationType: verification.verificationType,
        orderState: 'delivered',
        serverAcknowledged: false,
        isDemo: true,
      ),
      message:
          'Delivered locally for development only. Laravel has not acknowledged this completion.',
    );
  }
}

class UnavailableDriverDeliveryCompletionRepository
    implements DriverDeliveryCompletionRepository {
  const UnavailableDriverDeliveryCompletionRepository();
  @override
  DriverDeliveryCompletionDataSource get source =>
      DriverDeliveryCompletionDataSource.api;
  @override
  Future<DriverDeliveryCompletionResult> completeDelivery(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryPinReceipt verification}) async {
    return const DriverDeliveryCompletionResult.failure(
        reason: DriverDeliveryCompletionFailureReason.unavailable,
        message:
            'Could not confirm with Getin. Your order status has not changed. Retry.');
  }
}
