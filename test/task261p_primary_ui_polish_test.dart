import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/earnings/driver_earnings_screen.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';
import 'package:getin_driver/features/orders/driver_available_orders_screen.dart';
import 'package:getin_driver/features/profile/driver_profile_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Future<void> _scrollUntilText(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 8; attempt++) {
    final target = find.text(text);
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
  expect(find.text(text), findsOneWidget);
}

void main() {
  testWidgets('Task 261P keeps one compact active-delivery home card',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(
            config: _config,
            onResumeActiveDelivery: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery in progress'), findsOneWidget);
    expect(find.text('ACTIVE DELIVERY'), findsOneWidget);
    expect(find.text('Resume Delivery'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(
      find.textContaining('before receiving another delivery offer'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Task 261P keeps capacity copy driver-facing in Orders',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverAvailableOrdersScreen(
            config: _config,
            repository: DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeOrderCount: 1,
            activeOrderNumber: 'GD-POLISH-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Complete GD-POLISH-1 to receive another delivery offer.'),
      findsOneWidget,
    );
    expect(find.textContaining('V1 allows'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Task 261P adds earnings goal without backend-facing copy',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverEarningsScreen(config: _config)),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollUntilText(tester, 'TODAY’S DELIVERY GOAL');

    expect(find.text('TODAY’S DELIVERY GOAL'), findsOneWidget);
    expect(find.text('Driver commissions'), findsOneWidget);
    expect(find.textContaining('backend-driven'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Task 261P keeps long region out of compact profile stats',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverProfileScreen(config: _config)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned'), findsOneWidget);
    expect(find.textContaining('Region •'), findsNothing);
    expect(find.byKey(const Key('driver-profile-photo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
