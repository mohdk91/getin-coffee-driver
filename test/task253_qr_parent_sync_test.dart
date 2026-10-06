import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';

Future<void> _dragUntilBuilt(
  WidgetTester tester,
  Finder target, {
  Offset moveStep = const Offset(0, -220),
}) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, moveStep);
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-UAT-9001',
    status: 'Arrived at customer • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
    state: DriverDeliveryState.arrivedCustomer,
  );

  testWidgets(
      'Task 253 QR success synchronizes parent timeline and unlocks completion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final qrRepository = DemoDriverDeliveryQrRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          timeline: DriverDeliveryStateMachine.seed(
            orderNumber: delivery.orderNumber,
            currentState: DriverDeliveryState.arrivedCustomer,
          ),
          destinationRepository:
              const DemoDriverDeliveryDestinationRepository(),
          qrRepository: qrRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final qr = find.widgetWithText(OutlinedButton, 'Scan Customer QR');
    await _dragUntilBuilt(tester, qr);
    await tester.tap(qr);
    await tester.pumpAndSettle();

    final scan = find.widgetWithText(FilledButton, 'Simulate Customer QR Scan');
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();
    expect(find.text('QR VERIFIED'), findsOneWidget);

    // Use the app-bar back path that failed during physical UAT.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Phase B places the verification card before secondary destination and
    // timeline detail. First confirm the parent received the QR receipt.
    final qrVerified = find.text('QR Verified');
    await _dragUntilBuilt(
      tester,
      qrVerified,
      moveStep: const Offset(0, 220),
    );

    // The timeline is collapsed by default in the new cockpit. Its compact
    // status pill remains authoritative and should reflect the synchronized
    // verification state without requiring expansion.
    final verificationComplete = find.text('VERIFICATION COMPLETE');
    await _dragUntilBuilt(tester, verificationComplete);
    expect(find.textContaining('Verification pending'), findsNothing);

    // Completion remains a separate server-confirmed action below the
    // timeline and must be unlocked after successful verification.
    final complete = find.widgetWithText(FilledButton, 'Complete Delivery');
    await _dragUntilBuilt(tester, complete);
    final completeButton = tester.widget<FilledButton>(complete);
    expect(completeButton.onPressed, isNotNull);

    // Verification must not skip the separate completion action.
    expect(find.textContaining('Delivered •'), findsNothing);
  });
}
