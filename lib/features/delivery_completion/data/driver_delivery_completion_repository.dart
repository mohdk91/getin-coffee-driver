import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../delivery_verification/domain/driver_delivery_pin_models.dart';
import '../domain/driver_delivery_completion_models.dart';

abstract interface class DriverDeliveryCompletionRepository {
  DriverDeliveryCompletionDataSource get source;

  Future<DriverDeliveryCompletionResult> completeDelivery({
    required String orderNumber,
    required DriverDeliveryPinReceipt verification,
  });
}

class DriverDeliveryCompletionRepositoryFactory {
  DriverDeliveryCompletionRepositoryFactory._();

  static DriverDeliveryCompletionRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverDeliveryCompletionRepository()
        : const UnavailableDriverDeliveryCompletionRepository();
  }
}

class DemoDriverDeliveryCompletionRepository
    implements DriverDeliveryCompletionRepository {
  const DemoDriverDeliveryCompletionRepository();

  @override
  DriverDeliveryCompletionDataSource get source =>
      DriverDeliveryCompletionDataSource.demo;

  @override
  Future<DriverDeliveryCompletionResult> completeDelivery({
    required String orderNumber,
    required DriverDeliveryPinReceipt verification,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));

    final normalizedOrder = orderNumber.trim().toUpperCase();
    if (!deliveryVerificationMatchesOrder(
      verification: verification,
      orderNumber: normalizedOrder,
    )) {
      return const DriverDeliveryCompletionResult.failure(
        reason: DriverDeliveryCompletionFailureReason.verificationMismatch,
        message:
            'Delivery verification does not belong to this order. The order status has not changed.',
      );
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
  Future<DriverDeliveryCompletionResult> completeDelivery({
    required String orderNumber,
    required DriverDeliveryPinReceipt verification,
  }) async {
    return const DriverDeliveryCompletionResult.failure(
      reason: DriverDeliveryCompletionFailureReason.unavailable,
      message:
          'Could not confirm with Getin. Your order status has not changed. Retry.',
    );
  }
}
