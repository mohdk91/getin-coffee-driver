import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/navigation/driver_navigation_push_guard.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/orders/data/driver_order_acceptance_repository.dart';
import 'package:getin_driver/features/orders/domain/driver_order_acceptance_models.dart';
import 'package:getin_driver/features/orders/driver_available_orders_screen.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/eligibility/domain/driver_order_eligibility_models.dart';
import 'package:getin_driver/features/recovery/data/driver_runtime_recovery_store.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
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

class _CountingHomeRepository implements DriverHomeRepository {
  int calls = 0;

  @override
  DriverHomeDataSource get source => DriverHomeDataSource.demo;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    calls += 1;
    return DriverHomeLoadResult.success(
      DriverHomeSnapshot(
        availability: DriverAvailabilityState.online,
        activeDelivery: null,
        availableOrders: 0,
        completedToday: 0,
        earningsToday: 0,
        currencyCode: 'EGP',
        rating: 4.9,
        ratingCount: 126,
        unreadNotifications: 0,
        gpsState: DriverGpsState.ready,
        internetConnected: true,
        updatedAt: DateTime(2026, 9, 27, 2),
      ),
    );
  }
}

class _SlowAcceptanceRepository implements DriverOrderAcceptanceRepository {
  int calls = 0;
  final Completer<DriverOrderAcceptanceResult> completer =
      Completer<DriverOrderAcceptanceResult>();

  @override
  DriverOrderAcceptanceDataSource get source =>
      DriverOrderAcceptanceDataSource.api;

  @override
  Future<DriverOrderAcceptanceResult> accept({
    required DriverOrderCandidate order,
    required String driverId,
  }) {
    calls += 1;
    return completer.future;
  }
}

void main() {
  test('Task 40 navigation guard drops duplicate pushes while one is active',
      () async {
    final guard = DriverNavigationPushGuard();
    final operation = Completer<void>();
    var calls = 0;

    final first = guard.run('notifications', () {
      calls += 1;
      return operation.future;
    });
    final second = await guard.run('notifications', () async {
      calls += 1;
    });

    expect(second, isFalse);
    expect(calls, 1);
    expect(guard.isInFlight('notifications'), isTrue);

    operation.complete();
    expect(await first, isTrue);
    expect(guard.isInFlight('notifications'), isFalse);
  });

  testWidgets(
      'Task 40 restores active order after app restart and reloads on resume',
      (tester) async {
    final homeRepository = _CountingHomeRepository();
    final recoveryStore = _MemoryRecoveryStore(
      const DriverRuntimeRecoverySnapshot(
        activeDelivery: DriverActiveDeliverySummary(
          orderNumber: 'GD-9090',
          status: 'Out for delivery',
          pickupBranch: 'Stanley',
          destinationArea: 'Gleem',
          etaMinutes: 9,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverFoundationShell(
          config: _config,
          homeRepository: homeRepository,
          recoveryStore: recoveryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The demo eligibility repository intentionally resolves after 140 ms.
    // Advance fake time so no eligibility timer survives widget disposal.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Active delivery • GD-9090'), findsOneWidget);
    final callsBeforeResume = homeRepository.calls;
    expect(callsBeforeResume, greaterThanOrEqualTo(1));

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump();
    // Resume starts another eligibility evaluation. Drain its 140 ms demo timer
    // before the test tears the widget tree down.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(homeRepository.calls, greaterThan(callsBeforeResume));
    expect(find.text('Active delivery • GD-9090'), findsOneWidget);
  });

  testWidgets('Task 40 compact Android layout keeps primary shell usable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverFoundationShell(
          config: _config,
          homeRepository: _CountingHomeRepository(),
          recoveryStore: _MemoryRecoveryStore(
            DriverRuntimeRecoverySnapshot.empty,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Task 40 allows only one acceptance request at a time',
      (tester) async {
    final acceptanceRepository = _SlowAcceptanceRepository();

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverAvailableOrdersScreen(
            config: _config,
            repository: const DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeOrderCount: 0,
            acceptanceRepository: acceptanceRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accept Delivery'), findsNWidgets(2));
    final firstAccept = find.text('Accept Delivery').first;

    // Intentionally tap twice before a rebuild. The synchronous in-flight guard
    // must prevent the second tap from starting a duplicate acceptance request.
    await tester.tap(firstAccept);
    await tester.tap(firstAccept);
    await tester.pump();

    expect(acceptanceRepository.calls, 1);
    expect(find.text('Acceptance locked'), findsOneWidget);

    acceptanceRepository.completer.complete(
      const DriverOrderAcceptanceResult(
        outcome: DriverOrderAcceptanceOutcome.serverFailure,
        message: 'Slow network simulation finished without accepting.',
      ),
    );
    await tester.pumpAndSettle();
  });
}
