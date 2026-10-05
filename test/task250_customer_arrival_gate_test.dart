import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';

Future<void> _dragUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 18 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-UAT-9001',
    status: 'Out for delivery • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
    state: DriverDeliveryState.outForDelivery,
  );

  testWidgets(
      'Task 250 requires explicit customer arrival before PIN or QR verification',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    DriverDeliveryState? changedState;
    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository:
              const DemoDriverDeliveryDestinationRepository(),
          onStateChanged: (value) => changedState = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final arrival = find.widgetWithText(FilledButton, 'Arrived at Customer');
    await _dragUntilBuilt(tester, arrival);

    final pinBefore = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enter Delivery Code'),
    );
    final qrBefore = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Scan Customer QR'),
    );
    expect(pinBefore.onPressed, isNull);
    expect(qrBefore.onPressed, isNull);
    expect(find.textContaining('Verification stays locked'), findsOneWidget);

    await tester.tap(arrival);
    await tester.pumpAndSettle();

    expect(changedState, DriverDeliveryState.arrivedCustomer);
    expect(find.text('Arrival Confirmed'), findsOneWidget);
    expect(find.text('Arrived at Customer'), findsOneWidget);

    final pinAfter = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enter Delivery Code'),
    );
    final qrAfter = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Scan Customer QR'),
    );
    expect(pinAfter.onPressed, isNotNull);
    expect(qrAfter.onPressed, isNotNull);
  });
}
