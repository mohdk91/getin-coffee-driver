import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/active_delivery/driver_active_delivery_timeline_card.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/route/data/driver_branch_route_repository.dart';
import 'package:getin_driver/features/route/driver_route_to_branch_screen.dart';

void main() {
  testWidgets('Task 262 keeps the delivery timeline compact until requested',
      (tester) async {
    final timeline = DriverDeliveryStateMachine.seed(
      orderNumber: 'GD-262',
      currentState: DriverDeliveryState.outForDelivery,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverActiveDeliveryTimelineCard(
            timeline: timeline,
            initiallyExpanded: false,
          ),
        ),
      ),
    );

    expect(find.text('Delivery timeline'), findsOneWidget);
    expect(find.text('Show timeline'), findsOneWidget);
    expect(find.text('Delivered'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('delivery-timeline-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Active Delivery Timeline'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('Task 262 puts the branch next action before secondary details',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const delivery = DriverActiveDeliverySummary(
      orderNumber: 'GD-262',
      status: 'Going to branch',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 19,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverRouteToBranchScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverBranchRouteRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.text('Arrived at Branch • Verify Pickup'), findsOneWidget);
  });
}
