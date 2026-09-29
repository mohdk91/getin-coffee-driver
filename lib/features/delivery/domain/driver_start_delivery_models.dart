enum DriverStartDeliveryDataSource { demo, api }

class DriverStartDeliveryReceipt {
  final String auditId;
  final String orderNumber;
  final String driverId;
  final DateTime startedAt;
  final double? latitude;
  final double? longitude;
  final bool serverAcknowledged;
  final bool isDemo;

  const DriverStartDeliveryReceipt({
    required this.auditId,
    required this.orderNumber,
    required this.driverId,
    required this.startedAt,
    required this.latitude,
    required this.longitude,
    required this.serverAcknowledged,
    required this.isDemo,
  });
}

class DriverStartDeliveryResult {
  final DriverStartDeliveryReceipt? receipt;
  final String? errorMessage;

  const DriverStartDeliveryResult._({this.receipt, this.errorMessage});

  const DriverStartDeliveryResult.success(DriverStartDeliveryReceipt value)
      : this._(receipt: value);

  const DriverStartDeliveryResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => receipt != null;
}
