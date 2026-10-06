import 'driver_delivery_pin_models.dart';

enum DriverDeliveryQrDataSource { demo, api }

enum DriverDeliveryQrFailureReason {
  invalidQr,
  expired,
  wrongOrder,
  wrongCustomer,
  wrongDriver,
  alreadyUsed,
  tooManyAttempts,
  cameraUnavailable,
  unavailable,
}

class DriverDeliveryQrChallenge {
  final String orderNumber;
  final String customerReference;
  final String assignedDriverReference;
  final DateTime expiresAt;
  final DateTime? usedAt;

  const DriverDeliveryQrChallenge({
    required this.orderNumber,
    required this.customerReference,
    required this.assignedDriverReference,
    required this.expiresAt,
    this.usedAt,
  });

  bool get isUsed => usedAt != null;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DriverDeliveryQrLoadResult {
  final DriverDeliveryQrChallenge? challenge;
  final DriverDeliveryPinReceipt? verifiedReceipt;
  final String? errorMessage;

  const DriverDeliveryQrLoadResult._({
    this.challenge,
    this.verifiedReceipt,
    this.errorMessage,
  });

  const DriverDeliveryQrLoadResult.success(
    DriverDeliveryQrChallenge value, {
    DriverDeliveryPinReceipt? verifiedReceipt,
  }) : this._(challenge: value, verifiedReceipt: verifiedReceipt);

  const DriverDeliveryQrLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => challenge != null;
}

class DriverDeliveryQrVerificationResult {
  final DriverDeliveryPinReceipt? receipt;
  final DriverDeliveryQrFailureReason? failureReason;
  final String message;

  const DriverDeliveryQrVerificationResult._({
    this.receipt,
    this.failureReason,
    required this.message,
  });

  const DriverDeliveryQrVerificationResult.success({
    required DriverDeliveryPinReceipt value,
    required String message,
  }) : this._(receipt: value, message: message);

  const DriverDeliveryQrVerificationResult.failure({
    required DriverDeliveryQrFailureReason reason,
    required String message,
  }) : this._(failureReason: reason, message: message);

  bool get isSuccess => receipt != null;
}

class DriverDeliveryQrScreenOutcome {
  final DriverDeliveryPinReceipt? receipt;
  final bool usePinFallback;

  const DriverDeliveryQrScreenOutcome._({
    this.receipt,
    required this.usePinFallback,
  });

  const DriverDeliveryQrScreenOutcome.verified(DriverDeliveryPinReceipt value)
      : this._(receipt: value, usePinFallback: false);

  const DriverDeliveryQrScreenOutcome.usePin() : this._(usePinFallback: true);
}
