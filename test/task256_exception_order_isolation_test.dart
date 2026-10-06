import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/uat/driver_uat_delivery_exception_store.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';
import 'package:getin_driver/features/delivery_exceptions/domain/driver_delivery_exception_models.dart';
import 'package:getin_driver/features/delivery_exceptions/driver_delivery_exception_screen.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/recovery/data/driver_runtime_recovery_store.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
  uatDemoRequested: true,
);

const _uatFailed = DriverActiveDeliverySummary(
  orderNumber: 'GD-UAT-9001',
  status: 'Failed delivery • Demo',
  pickupBranch: 'Stanley',
  destinationArea: 'San Stefano',
  etaMinutes: 19,
  state: DriverDeliveryState.failedDelivery,
);

DriverDeliveryExceptionReceipt _receipt({
  required String orderNumber,
  required String note,
}) =>
    DriverDeliveryExceptionReceipt(
      auditId: 'DEMO-EXCEPTION-$orderNumber-1',
      orderNumber: orderNumber,
      driverReference: 'DEMO-DRIVER-001',
      reason: DriverDeliveryExceptionReason.customerUnavailable,
      note: note,
      reportedAt: DateTime(2026, 10, 6, 13, 41),
      latitude: 31.24580,
      longitude: 29.96680,
      recommendedOrderState: 'failed_delivery',
      serverAcknowledged: false,
      isDemo: true,
    );

class _MemoryRecoveryStore implements DriverRuntimeRecoveryStore {
  DriverRuntimeRecoverySnapshot snapshot;

  _MemoryRecoveryStore(this.snapshot);

  @override
  Future<DriverRuntimeRecoverySnapshot> load() async => snapshot;

  @override
  Future<void> save(DriverRuntimeRecoverySnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

class _ConflictingDemoHomeRepository implements DriverHomeRepository {
  @override
  DriverHomeDataSource get source => DriverHomeDataSource.demo;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    return DriverHomeLoadResult.success(
      DriverHomeSnapshot(
        availability: DriverAvailabilityState.online,
        activeDelivery: const DriverActiveDeliverySummary(
          orderNumber: 'GD-3101',
          status: 'Going to branch',
          pickupBranch: 'Stanley',
          destinationArea: 'San Stefano',
          etaMinutes: 8,
          state: DriverDeliveryState.goingToBranch,
        ),
        availableOrders: 2,
        completedToday: 0,
        earningsToday: 0,
        currencyCode: 'EGP',
        rating: 4.9,
        ratingCount: 126,
        unreadNotifications: 0,
        gpsState: DriverGpsState.ready,
        internetConnected: true,
        updatedAt: DateTime(2026, 10, 6, 14),
      ),
    );
  }
}

void main() {
  setUp(() {
    DemoDriverDeliveryExceptionRepository.clearDemoState();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Task 256 demo exception repository isolates records by exact order',
      () async {
    const repository = DemoDriverDeliveryExceptionRepository();

    await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-3101',
      reason: DriverDeliveryExceptionReason.customerUnavailable,
      note: 'Wrong demo order note.',
    );
    await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-UAT-9001',
      reason: DriverDeliveryExceptionReason.customerUnavailable,
      note: 'Called customer twice, no answer.',
    );

    final uat = await repository.loadActiveException(
      apiOrderId: null,
      orderNumber: 'gd-uat-9001',
    );
    final seeded = await repository.loadActiveException(
      apiOrderId: null,
      orderNumber: 'gd-3101',
    );

    expect(uat?.orderNumber, 'GD-UAT-9001');
    expect(uat?.note, 'Called customer twice, no answer.');
    expect(seeded?.orderNumber, 'GD-3101');
    expect(seeded?.note, 'Wrong demo order note.');
  });

  test('Task 256 persisted UAT exception store isolates order keys', () async {
    final store = SharedPreferencesDriverUatDeliveryExceptionStore(
      forcePersistenceInTests: true,
    );
    await store.upsert(
      _receipt(orderNumber: 'GD-3101', note: 'Seeded note.'),
    );
    await store.upsert(
      _receipt(
        orderNumber: 'GD-UAT-9001',
        note: 'Called customer twice, no answer.',
      ),
    );

    final freshStore = SharedPreferencesDriverUatDeliveryExceptionStore(
      forcePersistenceInTests: true,
    );
    final uat = await freshStore.load('GD-UAT-9001');
    final seeded = await freshStore.load('GD-3101');
    final absent = await freshStore.load('GD-UAT-DOES-NOT-EXIST');

    expect(uat?.orderNumber, 'GD-UAT-9001');
    expect(uat?.note, 'Called customer twice, no answer.');
    expect(seeded?.orderNumber, 'GD-3101');
    expect(seeded?.note, 'Seeded note.');
    expect(absent, isNull);
  });

  testWidgets('Task 256 edit screen rejects a receipt from another order',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryExceptionScreen(
          delivery: _uatFailed,
          config: _config,
          repository: const DemoDriverDeliveryExceptionRepository(),
          existingReceipt: _receipt(
            orderNumber: 'GD-3101',
            note: 'Wrong demo order note.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('GD-UAT-9001 • San Stefano'), findsOneWidget);
    expect(find.text('What happened?'), findsOneWidget);
    expect(find.text('Update delivery issue'), findsNothing);
    expect(find.text('Wrong demo order note.'), findsNothing);
  });

  testWidgets(
      'Task 256 failed delivery recovery preserves exact UAT order over seeded demo home',
      (tester) async {
    final recoveryStore = _MemoryRecoveryStore(
      const DriverRuntimeRecoverySnapshot(activeDelivery: _uatFailed),
    );

    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverFoundationShell(
          config: _config,
          homeRepository: _ConflictingDemoHomeRepository(),
          recoveryStore: recoveryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Active delivery • GD-UAT-9001'), findsOneWidget);
    expect(find.text('Failed delivery • Demo'), findsWidgets);
    expect(find.text('View Failed Delivery'), findsOneWidget);
    expect(find.text('Active delivery • GD-3101'), findsNothing);
    expect(recoveryStore.snapshot.activeDelivery?.orderNumber, 'GD-UAT-9001');
    expect(
      recoveryStore.snapshot.activeDelivery?.resolvedState,
      DriverDeliveryState.failedDelivery,
    );
  });
}
