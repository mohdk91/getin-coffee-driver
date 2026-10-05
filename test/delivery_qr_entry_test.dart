import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';
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
    orderNumber: 'GD-2481',
    status: 'Out for delivery • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  testWidgets('Task 20 active delivery offers Enter Code OR Scan Customer QR',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository:
              const DemoDriverDeliveryDestinationRepository(),
          pinRepository: DemoDriverDeliveryPinRepository(),
          qrRepository: DemoDriverDeliveryQrRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _dragUntilBuilt(tester, find.text('Enter Delivery Code'));
    expect(find.text('Enter Delivery Code'), findsOneWidget);
    expect(find.text('Scan Customer QR'), findsOneWidget);
  });

  testWidgets('Task 20 QR result returns to delivery as QR Verified',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository:
              const DemoDriverDeliveryDestinationRepository(),
          pinRepository: DemoDriverDeliveryPinRepository(),
          qrRepository: DemoDriverDeliveryQrRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final arrived = find.widgetWithText(FilledButton, 'Arrived at Customer');
    await _dragUntilBuilt(tester, arrived);
    await tester.tap(arrived);
    await tester.pumpAndSettle();

    final qr = find.text('Scan Customer QR');
    await _dragUntilBuilt(tester, qr);
    await tester.tap(qr);
    await tester.pumpAndSettle();

    expect(find.text('Scan the customer delivery QR'), findsOneWidget);

    final scan = find.widgetWithText(FilledButton, 'Simulate Customer QR Scan');
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();

    final back = find.widgetWithText(FilledButton, 'Back to Delivery');
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.text('QR Verified'), findsOneWidget);
    expect(find.text('Scan Customer QR'), findsNothing);
  });
}
