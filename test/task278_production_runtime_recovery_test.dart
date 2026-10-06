import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/recovery/data/driver_runtime_recovery_coordinator.dart';
import 'package:getin_driver/features/recovery/data/driver_runtime_recovery_store.dart';

void main() {
  const production = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://portal.getincoffee.com/api',
  );

  test('Task 278 server runtime replaces local cached delivery', () async {
    final store = _MemoryStore(
      DriverRuntimeRecoverySnapshot(
        activeDelivery: _delivery('OLD-1'),
        lastSuccessfulSyncAt: DateTime(2026, 10, 6, 10),
      ),
    );
    final server = DriverRuntimeRecoverySnapshot(
      activeDelivery: _delivery('LIVE-9'),
      lastSuccessfulSyncAt: DateTime(2026, 10, 6, 12),
    );

    final result = await DriverRuntimeRecoveryCoordinator(
      config: production,
      store: store,
      remoteLoader: () async => server,
      clock: () => DateTime(2026, 10, 6, 12, 5),
    ).resolve();

    expect(result.source, DriverRuntimeRecoverySource.server);
    expect(result.readOnlyFallback, isFalse);
    expect(result.snapshot.activeDelivery?.orderNumber, 'LIVE-9');
    expect(store.value.activeDelivery?.orderNumber, 'LIVE-9');
  });

  test('Task 278 recent offline cache is read-only continuity only', () async {
    final store = _MemoryStore(
      DriverRuntimeRecoverySnapshot(
        activeDelivery: _delivery('CACHE-2'),
        lastSuccessfulSyncAt: DateTime(2026, 10, 6, 11),
      ),
    );

    final result = await DriverRuntimeRecoveryCoordinator(
      config: production,
      store: store,
      remoteLoader: () async => throw StateError('offline'),
      clock: () => DateTime(2026, 10, 6, 12),
    ).resolve();

    expect(result.source, DriverRuntimeRecoverySource.localCache);
    expect(result.readOnlyFallback, isTrue);
    expect(result.snapshot.activeDelivery?.orderNumber, 'CACHE-2');
    expect(result.warningMessage, contains('Reconnect'));
  });

  test('Task 278 stale production cache never restores an active delivery',
      () async {
    final store = _MemoryStore(
      DriverRuntimeRecoverySnapshot(
        activeDelivery: _delivery('STALE-3'),
        completedOrderNumber: 'DONE-1',
        lastSuccessfulSyncAt: DateTime(2026, 10, 4, 8),
      ),
    );

    final result = await DriverRuntimeRecoveryCoordinator(
      config: production,
      store: store,
      remoteLoader: () async => throw StateError('offline'),
      clock: () => DateTime(2026, 10, 6, 12),
    ).resolve();

    expect(result.readOnlyFallback, isTrue);
    expect(result.snapshot.activeDelivery, isNull);
    expect(result.snapshot.completedOrderNumber, 'DONE-1');
  });
}

DriverActiveDeliverySummary _delivery(String number) =>
    DriverActiveDeliverySummary(
      apiOrderId: 10,
      orderNumber: number,
      status: 'out_for_delivery',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 0,
    );

class _MemoryStore implements DriverRuntimeRecoveryStore {
  DriverRuntimeRecoverySnapshot value;

  _MemoryStore(this.value);

  @override
  Future<DriverRuntimeRecoverySnapshot> load() async => value;

  @override
  Future<void> save(DriverRuntimeRecoverySnapshot snapshot) async {
    value = snapshot;
  }
}
