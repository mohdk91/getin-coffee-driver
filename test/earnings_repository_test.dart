import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/earnings/data/driver_earnings_repository.dart';
import 'package:getin_driver/features/earnings/domain/driver_earnings_models.dart';

void main() {
  test('Task 26 demo Today earnings match dashboard total', () async {
    const repository = DemoDriverEarningsRepository();
    final result = await repository.load(DriverEarningsPeriod.today);

    expect(result.isSuccess, isTrue);
    expect(result.snapshot!.deliveryCount, 4);
    expect(result.snapshot!.totalEarnings, closeTo(485.50, 0.001));
    expect(result.snapshot!.tipsSupported, isTrue);
  });

  test('Task 26 periods grow from Today to Week to Month', () async {
    const repository = DemoDriverEarningsRepository();
    final today = (await repository.load(DriverEarningsPeriod.today)).snapshot!;
    final week = (await repository.load(DriverEarningsPeriod.week)).snapshot!;
    final month = (await repository.load(DriverEarningsPeriod.month)).snapshot!;

    expect(week.deliveryCount, greaterThan(today.deliveryCount));
    expect(month.deliveryCount, greaterThan(week.deliveryCount));
    expect(week.totalEarnings, greaterThan(today.totalEarnings));
    expect(month.totalEarnings, greaterThan(week.totalEarnings));
  });

  test('Task 26 per-delivery total includes all supported components',
      () async {
    const repository = DemoDriverEarningsRepository();
    final result = await repository.load(DriverEarningsPeriod.today);
    final item = result.snapshot!.deliveries.first;

    expect(item.orderNumber, 'GD-2481');
    expect(item.baseEarning, 70);
    expect(item.distanceBonus, 25);
    expect(item.peakBonus, 20);
    expect(item.tipAmount, 10);
    expect(item.adjustments, -2.5);
    expect(item.totalEarning, 122.5);
  });

  test('Task 26 production repository does not invent payout data', () async {
    const repository = UnavailableDriverEarningsRepository();
    final result = await repository.load(DriverEarningsPeriod.today);

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('Laravel API'));
    expect(result.errorMessage, contains('will not invent'));
  });
}
