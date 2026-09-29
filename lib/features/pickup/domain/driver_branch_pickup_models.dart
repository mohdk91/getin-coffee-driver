enum DriverBranchPickupDataSource { demo, api }

enum DriverBranchPickupVerificationMethod { qr, token }

extension DriverBranchPickupVerificationMethodPresentation
    on DriverBranchPickupVerificationMethod {
  String get label => switch (this) {
        DriverBranchPickupVerificationMethod.qr => 'Branch QR',
        DriverBranchPickupVerificationMethod.token => 'Pickup token',
      };
}

class DriverBranchPickupVerification {
  final String orderNumber;
  final String branchName;
  final DriverBranchPickupVerificationMethod method;
  final String verificationReference;
  final DateTime verifiedAt;

  const DriverBranchPickupVerification({
    required this.orderNumber,
    required this.branchName,
    required this.method,
    required this.verificationReference,
    required this.verifiedAt,
  });
}

class DriverBranchPickupVerificationResult {
  final DriverBranchPickupVerification? verification;
  final String? errorMessage;

  const DriverBranchPickupVerificationResult._({
    this.verification,
    this.errorMessage,
  });

  const DriverBranchPickupVerificationResult.success(
    DriverBranchPickupVerification value,
  ) : this._(verification: value);

  const DriverBranchPickupVerificationResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => verification != null;
}

class DriverBranchPickupReceipt {
  final String auditId;
  final String orderNumber;
  final String branchName;
  final String driverId;
  final DriverBranchPickupVerificationMethod verificationMethod;
  final String verificationReference;
  final DateTime verifiedAt;
  final DateTime receivedAt;
  final double? latitude;
  final double? longitude;
  final bool serverAcknowledged;
  final bool isDemo;

  const DriverBranchPickupReceipt({
    required this.auditId,
    required this.orderNumber,
    required this.branchName,
    required this.driverId,
    required this.verificationMethod,
    required this.verificationReference,
    required this.verifiedAt,
    required this.receivedAt,
    required this.latitude,
    required this.longitude,
    required this.serverAcknowledged,
    required this.isDemo,
  });
}

class DriverBranchPickupReceiveResult {
  final DriverBranchPickupReceipt? receipt;
  final String? errorMessage;

  const DriverBranchPickupReceiveResult._({this.receipt, this.errorMessage});

  const DriverBranchPickupReceiveResult.success(DriverBranchPickupReceipt value)
      : this._(receipt: value);

  const DriverBranchPickupReceiveResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => receipt != null;
}
