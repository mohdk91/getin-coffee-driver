import '../../home/domain/driver_home_models.dart';
import 'driver_order_eligibility_models.dart';

class DriverOrderEligibilityEngine {
  final double maxGpsAccuracyMeters;
  final Duration maxGpsAge;

  const DriverOrderEligibilityEngine({
    this.maxGpsAccuracyMeters = 50,
    this.maxGpsAge = const Duration(minutes: 3),
  });

  DriverOrderEligibilitySnapshot evaluate({
    required DriverEligibilityContext context,
    required List<DriverOrderCandidate> candidates,
  }) {
    return DriverOrderEligibilitySnapshot(
      context: context,
      decisions: candidates
          .map((order) => _evaluateOrder(context: context, order: order))
          .toList(growable: false),
    );
  }

  DriverOrderEligibilityDecision _evaluateOrder({
    required DriverEligibilityContext context,
    required DriverOrderCandidate order,
  }) {
    final gps = context.gps;
    final gpsDelta =
        gps == null ? null : context.evaluatedAt.difference(gps.capturedAt);
    final gpsAge = gpsDelta == null
        ? null
        : Duration(milliseconds: gpsDelta.inMilliseconds.abs());
    final gpsValid = gps != null &&
        gps.state == DriverGpsState.ready &&
        gps.accuracyMeters <= maxGpsAccuracyMeters &&
        gpsAge! <= maxGpsAge;

    final regionEligible = order.region == context.region;
    final branchEligible = context.allowedBranches.contains(order.pickupBranch);
    final distanceEligible =
        order.distanceToBranchKm <= context.deliveryRadiusKm &&
            order.deliveryDistanceKm <= context.deliveryRadiusKm;
    final vehicleEligible = order.allowedVehicleTypes.isEmpty ||
        order.allowedVehicleTypes.contains(context.vehicleType);

    return DriverOrderEligibilityDecision(
      order: order,
      checks: [
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.driverApproved,
          passed: context.driverApproved,
          detail: context.driverApproved
              ? 'Driver verification is approved.'
              : 'Only approved drivers may receive delivery jobs.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.driverOnline,
          passed: context.availability == DriverAvailabilityState.online,
          detail: context.availability == DriverAvailabilityState.online
              ? 'Driver is Online.'
              : 'Driver is ${context.availability.label}; new jobs stay hidden.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.validGps,
          passed: gpsValid,
          detail: gps == null
              ? 'No current GPS fix is available.'
              : gpsValid
                  ? 'GPS is current and within the accuracy threshold.'
                  : 'GPS is disabled, permission-limited, stale, or not accurate enough.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.eligibleRegion,
          passed: regionEligible,
          detail: regionEligible
              ? '${order.region} matches the assigned driver region.'
              : '${order.region} is outside ${context.region}.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.eligibleBranch,
          passed: branchEligible,
          detail: branchEligible
              ? '${order.pickupBranch} is an allowed branch.'
              : '${order.pickupBranch} is not assigned to this driver.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.acceptableDistance,
          passed: distanceEligible,
          detail: distanceEligible
              ? 'Pickup and delivery distances are within ${context.deliveryRadiusKm.toStringAsFixed(0)} km.'
              : 'Pickup or delivery distance exceeds ${context.deliveryRadiusKm.toStringAsFixed(0)} km.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.acceptableVehicle,
          passed: vehicleEligible,
          detail: vehicleEligible
              ? '${context.vehicleType} is accepted for this order.'
              : '${context.vehicleType} is not accepted for this order.',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.activeOrderCapacity,
          passed: context.hasOrderCapacity,
          detail: context.hasOrderCapacity
              ? '${context.activeOrderCount}/${context.maxActiveOrders} active-order slots are in use.'
              : 'Active-order capacity is full (${context.activeOrderCount}/${context.maxActiveOrders}).',
        ),
        DriverEligibilityRuleCheck(
          rule: DriverOrderEligibilityRule.orderAvailable,
          passed: order.isAvailable,
          detail: order.isAvailable
              ? 'Order is still available.'
              : 'Order is no longer available.',
        ),
      ],
    );
  }
}
