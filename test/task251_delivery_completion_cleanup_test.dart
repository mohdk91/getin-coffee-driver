import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/active_delivery/driver_active_delivery_timeline_card.dart';
import 'package:getin_driver/features/delivery_completion/data/driver_delivery_completion_repository.dart';
import 'package:getin_driver/features/delivery_completion/driver_complete_delivery_card.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

const _delivery = DriverActiveDeliverySummary(
  orderNumber: 'GD-UAT-9001',
  status: 'Verification pending',
  pickupBranch: 'Stanley',
  destinationArea: 'San Stefano',
  etaMinutes: 19,
  state: DriverDeliveryState.verificationPending,
);

DriverDeliveryPinReceipt _verification() {
  return DriverDeliveryPinReceipt(
    auditId: 'PIN-UAT-9001',
    orderNumber: 'GD-UAT-9001',
    customerReference: 'DEMO-CUSTOMER-GD-UAT-9001',
    assignedDriverReference: 'DEMO-DRIVER-001',
    verifiedAt: DateTime(2026, 10, 6, 2, 15),
    verificationType: 'pin',
    serverAcknowledged: false,
    isDemo: true,
  );
}

void main() {
  testWidgets(
    'Task 251 completion receipt delegates Back to Driver Home to shell cleanup',
    (tester) async {
      var returnedHome = false;

      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DriverCompleteDeliveryCard(
                delivery: _delivery,
                verification: _verification(),
                repository: const DemoDriverDeliveryCompletionRepository(),
                onReturnHome: () => returnedHome = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Complete Delivery'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Delivery Completed'), findsOneWidget);
      final homeButton = find.text('Back to Driver Home');
      await tester.ensureVisible(homeButton);
      await tester.tap(homeButton);
      await tester.pump();

      expect(returnedHome, isTrue);
    },
  );

  testWidgets(
    'Task 251 verified timeline displays verification complete instead of pending',
    (tester) async {
      final timeline = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-UAT-9001',
        currentState: DriverDeliveryState.verificationPending,
        source: 'task251_test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverActiveDeliveryTimelineCard(
              timeline: timeline,
              currentStateLabelOverride: 'Verification complete',
            ),
          ),
        ),
      );

      expect(find.text('VERIFICATION COMPLETE'), findsOneWidget);
      expect(find.text('Verification complete'), findsOneWidget);
      expect(find.text('VERIFICATION PENDING'), findsNothing);
      expect(find.text('Verification pending'), findsNothing);
    },
  );

  test('Task 251 shell clears active state and pops to its own route', () {
    final foundation = File(
      'lib/features/foundation/driver_foundation_shell.dart',
    ).readAsStringSync();
    final navigation = File(
      'lib/features/navigation/driver_delivery_navigation_screen.dart',
    ).readAsStringSync();

    expect(foundation, contains('_activeTimeline = null;'));
    expect(foundation, contains('_returnHomeAfterDeliveryCompletion'));
    expect(
      foundation,
      contains('popUntil((route) => identical(route, shellRoute))'),
    );
    expect(
      foundation,
      contains('onReturnHome: _returnHomeAfterDeliveryCompletion'),
    );
    expect(navigation, contains('onReturnHome: widget.onReturnHome'));
    expect(navigation, contains("'Verification complete'"));
  });
}
