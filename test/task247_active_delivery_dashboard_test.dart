import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/availability/data/driver_availability_repository.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';

void main() {
  testWidgets(
      'Task 247 dashboard prioritizes an active delivery and hides new capacity',
      (tester) async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );
    const active = DriverActiveDeliverySummary(
      orderNumber: 'GD-UAT-ACTIVE',
      status: 'Going to branch • Demo',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 8,
      state: DriverDeliveryState.goingToBranch,
    );
    DriverHomeSnapshot? emittedSnapshot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(
            config: config,
            repository: const UatDriverHomeRepository(),
            availabilityRepository: const DemoDriverAvailabilityRepository(),
            eligibilityRepository: const DemoDriverOrderEligibilityRepository(),
            activeDeliveryOverride: active,
            onSnapshotChanged: (snapshot) => emittedSnapshot = snapshot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery in progress'), findsOneWidget);
    expect(find.text('GD-UAT-ACTIVE'), findsOneWidget);
    expect(
      find.text(
        'Complete GD-UAT-ACTIVE before receiving another delivery offer.',
      ),
      findsOneWidget,
    );
    expect(emittedSnapshot?.availableOrders, 0);
    expect(tester.takeException(), isNull);
  });
}
