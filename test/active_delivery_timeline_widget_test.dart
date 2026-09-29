import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/active_delivery/driver_active_delivery_timeline_card.dart';

void main() {
  testWidgets('Task 24 timeline shows ordered active delivery states',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final timeline = DriverDeliveryStateMachine.seed(
      orderNumber: 'GD-2481',
      currentState: DriverDeliveryState.outForDelivery,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DriverActiveDeliveryTimelineCard(timeline: timeline),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Active Delivery Timeline'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Going to branch'), findsOneWidget);
    expect(find.text('Arrived at branch'), findsOneWidget);
    expect(find.text('Picked up'), findsOneWidget);
    expect(find.text('Out for delivery'), findsOneWidget);
    expect(find.text('Arrived at customer'), findsOneWidget);
    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('CURRENT'), findsOneWidget);
  });

  testWidgets('Task 24 problem state explains progression lock',
      (tester) async {
    final timeline = DriverDeliveryStateMachine.seed(
      orderNumber: 'GD-2481',
      currentState: DriverDeliveryState.returnedToBranch,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverActiveDeliveryTimelineCard(timeline: timeline),
        ),
      ),
    );

    expect(find.text('RETURNED TO BRANCH'), findsOneWidget);
    expect(find.textContaining('Normal delivery progression is locked'),
        findsOneWidget);
  });
}
