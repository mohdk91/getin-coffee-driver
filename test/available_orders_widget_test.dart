import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/orders/data/driver_order_acceptance_repository.dart';
import 'package:getin_driver/features/orders/driver_available_orders_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Future<void> _scrollUntilText(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 10; attempt++) {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.drag(scrollable, const Offset(0, -280));
    await tester.pumpAndSettle();
  }
  expect(find.text(text), findsWidgets);
}

void main() {
  testWidgets('Task 10 renders only eligible new-order cards', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverAvailableOrdersScreen(
            config: _config,
            repository: DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeOrderCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available / New Orders'), findsOneWidget);
    expect(find.text('GD-3101'), findsOneWidget);
    expect(find.text('San Stefano'), findsWidgets);
    expect(find.text('EGP 72'), findsOneWidget);
    expect(find.text('Accept Delivery'), findsWidgets);

    await _scrollUntilText(tester, 'GD-3102');
    expect(find.text('GD-3102'), findsOneWidget);

    expect(find.text('GD-3103'), findsNothing);
    expect(find.text('GD-3104'), findsNothing);
    expect(find.text('GD-3105'), findsNothing);
    expect(find.text('GD-3106'), findsNothing);
  });

  testWidgets('Task 10 details keep customer private data hidden',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverAvailableOrdersScreen(
            config: _config,
            repository: DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeOrderCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final details = find.text('Details').first;
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();

    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Pickup branch'), findsOneWidget);
    expect(find.text('Destination area'), findsOneWidget);
    expect(find.text('Estimated driver earning'), findsOneWidget);
    expect(find.text('Customer name'), findsNothing);
    expect(find.text('Customer phone'), findsNothing);
    expect(find.text('Exact address'), findsNothing);
  });

  testWidgets('Task 10 order card connects to Task 11 acceptance repository',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final acceptanceRepository = DemoDriverOrderAcceptanceRepository(
      lockStore: DemoOrderLockStore(),
      responseDelay: Duration.zero,
      seedTakenOrder: false,
    );

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

    final accept = find.text('Accept Delivery').first;
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('GD-3101 accepted'), findsOneWidget);
  });

  testWidgets('Task 10 hides new orders while V1 capacity is full',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverAvailableOrdersScreen(
            config: _config,
            repository: DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeOrderCount: 1,
            activeOrderNumber: 'GD-2481',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No new orders right now'), findsOneWidget);
    expect(find.textContaining('Finish GD-2481'), findsOneWidget);
    expect(find.text('GD-3101'), findsNothing);
    expect(find.text('Accept Delivery'), findsNothing);
  });
}
