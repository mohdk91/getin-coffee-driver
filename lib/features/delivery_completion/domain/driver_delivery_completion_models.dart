import '../../delivery_verification/domain/driver_delivery_pin_models.dart';

enum DriverDeliveryCompletionDataSource { demo, api }

enum DriverDeliveryCompletionFailureReason {
  verificationRequired,
  verificationMismatch,
  unavailable,
}

class DriverDeliveryCompletionReceipt {
  final String auditId;
  final String orderNumber;
  final String driverReference;
  final DateTime completedAt;
  final DateTime? serverTimestamp;
  final double? latitude;
  final double? longitude;
  final String verificationType;
  final String orderState;
  final bool serverAcknowledged;
  final bool isDemo;

  const DriverDeliveryCompletionReceipt({
    required this.auditId,
    required this.orderNumber,
    required this.driverReference,
    required this.completedAt,
    required this.serverTimestamp,
    required this.latitude,
    required this.longitude,
    required this.verificationType,
    required this.orderState,
    required this.serverAcknowledged,
    required this.isDemo,
  });
}

class DriverDeliveryCompletionResult {
  final DriverDeliveryCompletionReceipt? receipt;
  final DriverDeliveryCompletionFailureReason? failureReason;
  final String message;

  const DriverDeliveryCompletionResult._({
    this.receipt,
    this.failureReason,
    required this.message,
  });

  const DriverDeliveryCompletionResult.success({
    required DriverDeliveryCompletionReceipt value,
    required String message,
  }) : this._(receipt: value, message: message);

  const DriverDeliveryCompletionResult.failure({
    required DriverDeliveryCompletionFailureReason reason,
    required String message,
  }) : this._(failureReason: reason, message: message);

  bool get isSuccess => receipt != null;
}

bool deliveryVerificationMatchesOrder({
  required DriverDeliveryPinReceipt verification,
  required String orderNumber,
}) {
  return verification.orderNumber.trim().toUpperCase() ==
      orderNumber.trim().toUpperCase();
}
