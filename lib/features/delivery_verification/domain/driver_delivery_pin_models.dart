enum DriverDeliveryPinDataSource { demo, api }

enum DriverDeliveryPinFailureReason {
  invalidCode,
  expired,
  wrongOrder,
  wrongCustomer,
  wrongDriver,
  alreadyUsed,
  tooManyAttempts,
  unavailable,
}

class DriverDeliveryPinChallenge {
  final String orderNumber;
  final String customerReference;
  final String assignedDriverReference;
  final int codeLength;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final int failedAttempts;
  final int maxAttempts;
  final DateTime? lockedAt;

  const DriverDeliveryPinChallenge({
    required this.orderNumber,
    required this.customerReference,
    required this.assignedDriverReference,
    required this.codeLength,
    required this.expiresAt,
    this.usedAt,
    this.failedAttempts = 0,
    this.maxAttempts = 3,
    this.lockedAt,
  });

  bool get isUsed => usedAt != null;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAttemptLocked => failedAttempts >= maxAttempts;
  int get remainingAttempts =>
      failedAttempts >= maxAttempts ? 0 : maxAttempts - failedAttempts;
}

class DriverDeliveryPinLoadResult {
  final DriverDeliveryPinChallenge? challenge;
  final String? errorMessage;

  const DriverDeliveryPinLoadResult._({this.challenge, this.errorMessage});

  const DriverDeliveryPinLoadResult.success(DriverDeliveryPinChallenge value)
      : this._(challenge: value);

  const DriverDeliveryPinLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => challenge != null;
}

class DriverDeliveryPinReceipt {
  final String auditId;
  final String orderNumber;
  final String customerReference;
  final String assignedDriverReference;
  final DateTime verifiedAt;
  final String verificationType;
  final bool serverAcknowledged;
  final bool isDemo;

  const DriverDeliveryPinReceipt({
    required this.auditId,
    required this.orderNumber,
    required this.customerReference,
    required this.assignedDriverReference,
    required this.verifiedAt,
    required this.verificationType,
    required this.serverAcknowledged,
    required this.isDemo,
  });
}

class DriverDeliveryPinVerificationResult {
  final DriverDeliveryPinReceipt? receipt;
  final DriverDeliveryPinFailureReason? failureReason;
  final String message;

  const DriverDeliveryPinVerificationResult._({
    this.receipt,
    this.failureReason,
    required this.message,
  });

  const DriverDeliveryPinVerificationResult.success({
    required DriverDeliveryPinReceipt value,
    required String message,
  }) : this._(receipt: value, message: message);

  const DriverDeliveryPinVerificationResult.failure({
    required DriverDeliveryPinFailureReason reason,
    required String message,
  }) : this._(failureReason: reason, message: message);

  bool get isSuccess => receipt != null;
}
