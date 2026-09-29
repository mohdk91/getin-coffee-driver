import '../../home/domain/driver_home_models.dart';
import '../../location/domain/driver_location_models.dart';

enum DriverOrderEligibilityRule {
  driverApproved,
  driverOnline,
  validGps,
  eligibleRegion,
  eligibleBranch,
  acceptableDistance,
  acceptableVehicle,
  activeOrderCapacity,
  orderAvailable,
}

extension DriverOrderEligibilityRulePresentation on DriverOrderEligibilityRule {
  String get label => switch (this) {
        DriverOrderEligibilityRule.driverApproved => 'Driver approved',
        DriverOrderEligibilityRule.driverOnline => 'Driver Online',
        DriverOrderEligibilityRule.validGps => 'Valid GPS',
        DriverOrderEligibilityRule.eligibleRegion => 'Eligible region',
        DriverOrderEligibilityRule.eligibleBranch => 'Eligible branch',
        DriverOrderEligibilityRule.acceptableDistance => 'Distance allowed',
        DriverOrderEligibilityRule.acceptableVehicle => 'Vehicle allowed',
        DriverOrderEligibilityRule.activeOrderCapacity => 'Order capacity',
        DriverOrderEligibilityRule.orderAvailable => 'Order still available',
      };
}

class DriverEligibilityContext {
  final bool driverApproved;
  final DriverAvailabilityState availability;
  final DriverGpsFix? gps;
  final String region;
  final String zone;
  final List<String> allowedBranches;
  final double deliveryRadiusKm;
  final String vehicleType;
  final int activeOrderCount;
  final int maxActiveOrders;
  final DateTime evaluatedAt;

  const DriverEligibilityContext({
    required this.driverApproved,
    required this.availability,
    required this.gps,
    required this.region,
    required this.zone,
    required this.allowedBranches,
    required this.deliveryRadiusKm,
    required this.vehicleType,
    required this.activeOrderCount,
    required this.maxActiveOrders,
    required this.evaluatedAt,
  });

  bool get hasOrderCapacity => activeOrderCount < maxActiveOrders;
}

class DriverOrderCandidate {
  final String orderNumber;
  final String pickupBranch;
  final String region;
  final String zone;
  final String destinationArea;
  final double distanceToBranchKm;
  final double deliveryDistanceKm;
  final int estimatedDurationMinutes;
  final int bagCount;
  final double estimatedDriverEarning;
  final String currencyCode;
  final List<String> allowedVehicleTypes;
  final bool isAvailable;

  const DriverOrderCandidate({
    required this.orderNumber,
    required this.pickupBranch,
    required this.region,
    required this.zone,
    this.destinationArea = 'Delivery area',
    required this.distanceToBranchKm,
    required this.deliveryDistanceKm,
    this.estimatedDurationMinutes = 0,
    this.bagCount = 1,
    this.estimatedDriverEarning = 0,
    this.currencyCode = 'EGP',
    required this.allowedVehicleTypes,
    required this.isAvailable,
  });
}

class DriverEligibilityRuleCheck {
  final DriverOrderEligibilityRule rule;
  final bool passed;
  final String detail;

  const DriverEligibilityRuleCheck({
    required this.rule,
    required this.passed,
    required this.detail,
  });
}

class DriverOrderEligibilityDecision {
  final DriverOrderCandidate order;
  final List<DriverEligibilityRuleCheck> checks;

  const DriverOrderEligibilityDecision({
    required this.order,
    required this.checks,
  });

  bool get isEligible => checks.every((check) => check.passed);

  List<DriverEligibilityRuleCheck> get failedChecks =>
      checks.where((check) => !check.passed).toList(growable: false);
}

class DriverOrderEligibilitySnapshot {
  final DriverEligibilityContext context;
  final List<DriverOrderEligibilityDecision> decisions;

  const DriverOrderEligibilitySnapshot({
    required this.context,
    required this.decisions,
  });

  List<DriverOrderEligibilityDecision> get eligibleOrders => decisions
      .where((decision) => decision.isEligible)
      .toList(growable: false);

  List<DriverOrderEligibilityDecision> get rejectedOrders => decisions
      .where((decision) => !decision.isEligible)
      .toList(growable: false);
}
