import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/recovery/data/driver_runtime_recovery_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Task 40 persists active delivery and last sync for restart recovery',
      () async {
    final store = SharedPreferencesDriverRuntimeRecoveryStore();
    final lastSync = DateTime(2026, 9, 27, 1, 55);

    await store.save(
      DriverRuntimeRecoverySnapshot(
        activeDelivery: const DriverActiveDeliverySummary(
          orderNumber: 'GD-4001',
          status: 'Verification pending',
          pickupBranch: 'Stanley',
          destinationArea: 'San Stefano',
          etaMinutes: 3,
          state: DriverDeliveryState.verificationPending,
        ),
        completedOrderNumber: 'GD-3999',
        lastSuccessfulSyncAt: lastSync,
      ),
    );

    final restored = await store.load();
    expect(restored.activeDelivery?.orderNumber, 'GD-4001');
    expect(
      restored.activeDelivery?.resolvedState,
      DriverDeliveryState.verificationPending,
    );
    expect(restored.completedOrderNumber, 'GD-3999');
    expect(restored.lastSuccessfulSyncAt, lastSync);
  });

  test('Task 40 ignores corrupt recovery cache instead of crashing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'driver.runtime.recovery.v1': '{not-valid-json',
    });
    final store = SharedPreferencesDriverRuntimeRecoveryStore();

    final restored = await store.load();
    expect(restored.activeDelivery, isNull);
    expect(restored.completedOrderNumber, isNull);
  });
}
