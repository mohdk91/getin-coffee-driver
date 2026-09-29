import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/order_history/driver_order_history_screen.dart';

void main() {
  const config =
      AppConfig(environment: AppEnvironment.development, apiBaseUrl: '');

  testWidgets('Task 25 renders four order tabs and filters', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverOrderHistoryScreen(
            config: config,
            eligibilityRepository: DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeDelivery: null,
            driverApproved: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New / Available'), findsOneWidget);
    expect(find.text('Active / On Delivery'), findsOneWidget);
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.byTooltip('Filters'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Task 25 delivered tab supports order-number search',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverOrderHistoryScreen(
            config: config,
            eligibilityRepository: DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeDelivery: null,
            driverApproved: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivered').first);
    await tester.pumpAndSettle();
    expect(find.text('GD-2476'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'GD-2468');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'GD-2468',
      ),
      findsOneWidget,
    );
    expect(find.text('GD-2476'), findsNothing);
  });
}
