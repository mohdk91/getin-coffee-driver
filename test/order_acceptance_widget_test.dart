import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/eligibility/domain/driver_order_eligibility_models.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/orders/data/driver_order_acceptance_repository.dart';
import 'package:getin_driver/features/orders/domain/driver_order_acceptance_models.dart';
import 'package:getin_driver/features/orders/driver_available_orders_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

class _ScriptedAcceptanceRepository implements DriverOrderAcceptanceRepository {
  final List<DriverOrderAcceptanceResult> results;
  final Duration delay;
  int calls = 0;

  _ScriptedAcceptanceRepository(
    this.results, {
    this.delay = Duration.zero,
  });

  @override
  DriverOrderAcceptanceDataSource get source =>
      DriverOrderAcceptanceDataSource.demo;

  @override
  Future<DriverOrderAcceptanceResult> accept({
    required DriverOrderCandidate order,
    required String driverId,
  }) async {
    await Future<void>.delayed(delay);
    final index = calls < results.length ? calls : results.length - 1;
    calls += 1;
    return results[index];
  }
}

Future<void> _pumpOrders(
  WidgetTester tester,
  DriverOrderAcceptanceRepository acceptanceRepository,
) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DriverAvailableOrdersScreen(
          config: _config,
          repository: const DemoDriverOrderEligibilityRepository(),
          acceptanceRepository: acceptanceRepository,
          availability: DriverAvailabilityState.online,
          activeOrderCount: 0,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Task 11 shows accepting then accepted state', (tester) async {
    final repository = _ScriptedAcceptanceRepository(
      [
        DriverOrderAcceptanceResult(
          outcome: DriverOrderAcceptanceOutcome.accepted,
          message: 'Delivery accepted.',
          lockToken: 'lock-1',
          acceptedAt: DateTime(2026, 9, 25),
        ),
      ],
      delay: const Duration(milliseconds: 250),
    );

    await _pumpOrders(tester, repository);

    final accept = find.text('Accept Delivery').first;
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pump();

    expect(find.text('Accepting…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('GD-3101 accepted'), findsOneWidget);
  });

  testWidgets('Task 11 already-taken result prevents another accept',
      (tester) async {
    final repository = _ScriptedAcceptanceRepository(
      const [
        DriverOrderAcceptanceResult(
          outcome: DriverOrderAcceptanceOutcome.alreadyTaken,
          message: 'Another driver accepted this delivery first.',
        ),
      ],
    );

    await _pumpOrders(tester, repository);

    final accept = find.text('Accept Delivery').first;
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();

    expect(find.textContaining('Another driver accepted'), findsOneWidget);
    expect(find.text('GD-3101'), findsNothing);
  });

  testWidgets('Task 11 timeout and server failure expose retry',
      (tester) async {
    final repository = _ScriptedAcceptanceRepository(
      const [
        DriverOrderAcceptanceResult(
          outcome: DriverOrderAcceptanceOutcome.timeout,
          message: 'Acceptance timed out. No order status changed.',
        ),
        DriverOrderAcceptanceResult(
          outcome: DriverOrderAcceptanceOutcome.serverFailure,
          message: 'Server could not confirm acceptance.',
        ),
        DriverOrderAcceptanceResult(
          outcome: DriverOrderAcceptanceOutcome.accepted,
          message: 'Delivery accepted.',
          lockToken: 'lock-retry',
        ),
      ],
    );

    await _pumpOrders(tester, repository);

    var action = find.text('Accept Delivery').first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Retry Accept'), findsOneWidget);
    expect(find.textContaining('timed out'), findsWidgets);

    action = find.text('Retry Accept').first;
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Retry Accept'), findsOneWidget);
    expect(find.textContaining('Server could not confirm'), findsWidgets);

    action = find.text('Retry Accept').first;
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Accepted'), findsOneWidget);
  });
}
