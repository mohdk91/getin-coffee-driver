enum DriverDeliveryExceptionDataSource { demo, api }

enum DriverDeliveryExceptionReason {
  customerUnavailable,
  wrongAddress,
  customerRefused,
  cannotAccessBuilding,
  damagedOrder,
  safetyIssue,
  supportRequired,
  returnToBranch,
}

extension DriverDeliveryExceptionReasonX on DriverDeliveryExceptionReason {
  String get label => switch (this) {
        DriverDeliveryExceptionReason.customerUnavailable =>
          'Customer unavailable',
        DriverDeliveryExceptionReason.wrongAddress => 'Wrong address',
        DriverDeliveryExceptionReason.customerRefused => 'Customer refused',
        DriverDeliveryExceptionReason.cannotAccessBuilding =>
          'Cannot access building',
        DriverDeliveryExceptionReason.damagedOrder => 'Damaged order',
        DriverDeliveryExceptionReason.safetyIssue => 'Safety issue',
        DriverDeliveryExceptionReason.supportRequired => 'Support required',
        DriverDeliveryExceptionReason.returnToBranch => 'Return to branch',
      };

  String get description => switch (this) {
        DriverDeliveryExceptionReason.customerUnavailable =>
          'The customer cannot be reached or is not available at the delivery location.',
        DriverDeliveryExceptionReason.wrongAddress =>
          'The provided destination appears incorrect or cannot be matched to the delivery.',
        DriverDeliveryExceptionReason.customerRefused =>
          'The customer has declined to receive the order.',
        DriverDeliveryExceptionReason.cannotAccessBuilding =>
          'The driver cannot safely access the building or delivery point.',
        DriverDeliveryExceptionReason.damagedOrder =>
          'The order or packaging appears damaged and should not be silently handed over.',
        DriverDeliveryExceptionReason.safetyIssue =>
          'There is a driver, customer, road, location, or delivery safety concern.',
        DriverDeliveryExceptionReason.supportRequired =>
          'The delivery needs Getin operations/support assistance before it can continue.',
        DriverDeliveryExceptionReason.returnToBranch =>
          'The order needs to be returned to the pickup branch instead of being completed.',
      };

  String get recommendedOrderState => switch (this) {
        DriverDeliveryExceptionReason.returnToBranch => 'returned_to_branch',
        _ => 'failed_delivery',
      };
}

class DriverDeliveryExceptionReceipt {
  final String auditId;
  final String orderNumber;
  final String driverReference;
  final DriverDeliveryExceptionReason reason;
  final String note;
  final DateTime reportedAt;
  final double? latitude;
  final double? longitude;
  final String recommendedOrderState;
  final bool serverAcknowledged;
  final bool isDemo;

  const DriverDeliveryExceptionReceipt({
    required this.auditId,
    required this.orderNumber,
    required this.driverReference,
    required this.reason,
    required this.note,
    required this.reportedAt,
    required this.latitude,
    required this.longitude,
    required this.recommendedOrderState,
    required this.serverAcknowledged,
    required this.isDemo,
  });
}

class DriverDeliveryExceptionResult {
  final DriverDeliveryExceptionReceipt? receipt;
  final String message;

  const DriverDeliveryExceptionResult._({
    this.receipt,
    required this.message,
  });

  const DriverDeliveryExceptionResult.success({
    required DriverDeliveryExceptionReceipt value,
    required String message,
  }) : this._(receipt: value, message: message);

  const DriverDeliveryExceptionResult.failure({required String message})
      : this._(message: message);

  bool get isSuccess => receipt != null;
}
