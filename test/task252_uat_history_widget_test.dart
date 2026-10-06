import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/uat/driver_uat_completed_delivery_store.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/order_history/data/driver_order_history_repository.dart';
import 'package:getin_driver/features/order_history/driver_order_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Task 252 persisted UAT completion is searchable in Delivered',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = SharedPreferencesDriverUatCompletedDeliveryStore(
      forcePersistenceInTests: true,
    );
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

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverOrderHistoryScreen(
            config: config,
            eligibilityRepository: const DemoDriverOrderEligibilityRepository(),
            availability: DriverAvailabilityState.online,
            activeDelivery: null,
            driverApproved: true,
            historyRepository:
                const UatDriverOrderHistoryRepository(completedStore: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delivered').first);
    await tester.pumpAndSettle();
    expect(find.text('GD-UAT-9001'), findsOneWidget);
    final uatOrderCard = find.widgetWithText(Card, 'GD-UAT-9001');
    expect(uatOrderCard, findsOneWidget);
    expect(
      find.descendant(of: uatOrderCard, matching: find.text('EGP 72')),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, 'GD-UAT-9001');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Card, 'GD-UAT-9001'), findsOneWidget);
    expect(find.widgetWithText(Card, 'GD-2476'), findsNothing);
  });
}
