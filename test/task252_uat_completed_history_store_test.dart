import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/uat/driver_uat_completed_delivery_store.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/order_history/data/driver_order_history_repository.dart';
import 'package:getin_driver/features/order_history/domain/driver_order_history_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = SharedPreferencesDriverUatCompletedDeliveryStore(
    forcePersistenceInTests: true,
  );
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
    uatDemoRequested: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Task 252 persists one completed UAT delivery across store instances',
      () async {
    final completedAt = DateTime.now();
    await store.upsert(
      DriverUatCompletedDeliveryRecord(
        orderNumber: 'GD-UAT-9001',
        pickupBranch: 'Stanley',
        destinationArea: 'San Stefano',
        completedAt: completedAt,
        bagCount: 2,
        driverEarning: 72,
        currencyCode: 'EGP',
      ),
    );

    const restartedStore = SharedPreferencesDriverUatCompletedDeliveryStore(
      forcePersistenceInTests: true,
    );
    final records = await restartedStore.load();

    expect(records, hasLength(1));
    expect(records.single.orderNumber, 'GD-UAT-9001');
    expect(records.single.bagCount, 2);
    expect(records.single.driverEarning, 72);
  });

  test('Task 252 UAT history and dashboard read the persisted completion',
      () async {
    await store.upsert(
      DriverUatCompletedDeliveryRecord(
        orderNumber: 'GD-UAT-9001',
        pickupBranch: 'Stanley',
        destinationArea: 'San Stefano',
        completedAt: DateTime.now(),
        bagCount: 2,
        driverEarning: 72,
        currencyCode: 'EGP',
      ),
    );

    const history = UatDriverOrderHistoryRepository(completedStore: store);
    final historyResult = await history.load();
    final persisted = historyResult.snapshot!.items.firstWhere(
      (item) => item.orderNumber == 'GD-UAT-9001',
    );
    expect(persisted.group, DriverOrderHistoryGroup.delivered);
    expect(persisted.driverEarning, 72);
    expect(persisted.bagCount, 2);

    const home = UatDriverHomeRepository(completedStore: store);
    final homeResult = await home.loadDashboard();
    expect(homeResult.snapshot!.completedToday, 1);
    expect(homeResult.snapshot!.earningsToday, 72);

    expect(
      DriverOrderHistoryRepositoryFactory.create(config),
      isA<UatDriverOrderHistoryRepository>(),
    );
  });

  test('Task 252 reset clears only persisted UAT completion stats', () async {
    await store.upsert(
      DriverUatCompletedDeliveryRecord(
        orderNumber: 'GD-UAT-9001',
        pickupBranch: 'Stanley',
        destinationArea: 'San Stefano',
        completedAt: DateTime.now(),
        bagCount: 2,
        driverEarning: 72,
        currencyCode: 'EGP',
      ),
    );

    await store.clear();

    expect(await store.load(), isEmpty);
    const home = UatDriverHomeRepository(completedStore: store);
    final homeResult = await home.loadDashboard();
    expect(homeResult.snapshot!.completedToday, 0);
    expect(homeResult.snapshot!.earningsToday, 0);
  });

  test('Task 252 upsert is idempotent by order number', () async {
    final now = DateTime.now();
    await store.upsert(
      DriverUatCompletedDeliveryRecord(
        orderNumber: 'GD-UAT-9001',
        pickupBranch: 'Stanley',
        destinationArea: 'San Stefano',
        completedAt: now.subtract(const Duration(minutes: 1)),
        bagCount: 2,
        driverEarning: 70,
        currencyCode: 'EGP',
      ),
    );
    await store.upsert(
      DriverUatCompletedDeliveryRecord(
        orderNumber: 'gd-uat-9001',
        pickupBranch: 'Stanley',
        destinationArea: 'San Stefano',
        completedAt: now,
        bagCount: 2,
        driverEarning: 72,
        currencyCode: 'EGP',
      ),
    );

    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.single.driverEarning, 72);
  });
}
