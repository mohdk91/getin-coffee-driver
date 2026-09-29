import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test(
      'online approved driver with free capacity receives only eligible demo jobs',
      () async {
    const repository = DemoDriverOrderEligibilityRepository();

    final result = await repository.evaluate(
      availability: DriverAvailabilityState.online,
      activeOrderCount: 0,
      driverApproved: true,
    );

    expect(result.isSuccess, isTrue);
    expect(result.snapshot, isNotNull);
    expect(result.snapshot!.decisions.length, 6);
    expect(result.snapshot!.eligibleOrders.length, 2);
    expect(
      result.snapshot!.eligibleOrders.map((item) => item.order.orderNumber),
      containsAll(<String>['GD-3101', 'GD-3102']),
    );
  });

  test('V1 active-order capacity hides all new jobs', () async {
    const repository = DemoDriverOrderEligibilityRepository();

    final result = await repository.evaluate(
      availability: DriverAvailabilityState.online,
      activeOrderCount: 1,
      driverApproved: true,
    );

    expect(result.isSuccess, isTrue);
    expect(result.snapshot!.context.maxActiveOrders, 1);
    expect(result.snapshot!.context.hasOrderCapacity, isFalse);
    expect(result.snapshot!.eligibleOrders, isEmpty);
  });

  test('offline and unapproved drivers receive no jobs', () async {
    const repository = DemoDriverOrderEligibilityRepository();

    final offline = await repository.evaluate(
      availability: DriverAvailabilityState.offline,
      activeOrderCount: 0,
      driverApproved: true,
    );
    final unapproved = await repository.evaluate(
      availability: DriverAvailabilityState.online,
      activeOrderCount: 0,
      driverApproved: false,
    );

    expect(offline.snapshot!.eligibleOrders, isEmpty);
    expect(unapproved.snapshot!.eligibleOrders, isEmpty);
  });

  test(
      'demo pool filters region branch distance vehicle and stale availability',
      () async {
    const repository = DemoDriverOrderEligibilityRepository();

    final result = await repository.evaluate(
      availability: DriverAvailabilityState.online,
      activeOrderCount: 0,
      driverApproved: true,
    );

    final rejected = {
      for (final decision in result.snapshot!.rejectedOrders)
        decision.order.orderNumber:
            decision.failedChecks.map((check) => check.rule.name).toSet(),
    };

    expect(rejected['GD-3103'], contains('eligibleRegion'));
    expect(rejected['GD-3103'], contains('eligibleBranch'));
    expect(rejected['GD-3104'], contains('acceptableDistance'));
    expect(rejected['GD-3105'], contains('acceptableVehicle'));
    expect(rejected['GD-3106'], contains('orderAvailable'));
  });
}
