enum DriverEarningsDataSource { demo, api }

enum DriverEarningsPeriod { today, week, month }

extension DriverEarningsPeriodLabel on DriverEarningsPeriod {
  String get label => switch (this) {
        DriverEarningsPeriod.today => 'Today',
        DriverEarningsPeriod.week => 'Week',
        DriverEarningsPeriod.month => 'Month',
      };
}

class DriverDeliveryEarning {
  final String orderNumber;
  final String pickupBranch;
  final String destinationArea;
  final DateTime deliveredAt;
  final double baseEarning;
  final double distanceBonus;
  final double peakBonus;
  final double? tipAmount;
  final double adjustments;
  final String currencyCode;
  final String? adjustmentNote;

  const DriverDeliveryEarning({
    required this.orderNumber,
    required this.pickupBranch,
    required this.destinationArea,
    required this.deliveredAt,
    required this.baseEarning,
    required this.distanceBonus,
    required this.peakBonus,
    required this.tipAmount,
    required this.adjustments,
    required this.currencyCode,
    this.adjustmentNote,
  });

  bool get tipsSupported => tipAmount != null;

  double get totalEarning =>
      baseEarning + distanceBonus + peakBonus + (tipAmount ?? 0) + adjustments;
}

class DriverEarningsSnapshot {
  final DriverEarningsPeriod period;
  final List<DriverDeliveryEarning> deliveries;
  final DateTime updatedAt;
  final bool rulesAreBackendDriven;

  const DriverEarningsSnapshot({
    required this.period,
    required this.deliveries,
    required this.updatedAt,
    this.rulesAreBackendDriven = true,
  });

  String get currencyCode =>
      deliveries.isEmpty ? 'EGP' : deliveries.first.currencyCode;

  int get deliveryCount => deliveries.length;

  double get baseTotal => deliveries.fold(
        0,
        (sum, item) => sum + item.baseEarning,
      );

  double get distanceBonusTotal => deliveries.fold(
        0,
        (sum, item) => sum + item.distanceBonus,
      );

  double get peakBonusTotal => deliveries.fold(
        0,
        (sum, item) => sum + item.peakBonus,
      );

  double get tipTotal => deliveries.fold(
        0,
        (sum, item) => sum + (item.tipAmount ?? 0),
      );

  double get adjustmentTotal => deliveries.fold(
        0,
        (sum, item) => sum + item.adjustments,
      );

  double get totalEarnings => deliveries.fold(
        0,
        (sum, item) => sum + item.totalEarning,
      );

  bool get tipsSupported => deliveries.any((item) => item.tipsSupported);
}

class DriverEarningsLoadResult {
  final DriverEarningsSnapshot? snapshot;
  final String? errorMessage;

  const DriverEarningsLoadResult._({this.snapshot, this.errorMessage});

  const DriverEarningsLoadResult.success(DriverEarningsSnapshot value)
      : this._(snapshot: value);

  const DriverEarningsLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}
