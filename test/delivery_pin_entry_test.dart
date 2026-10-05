import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';

Future<void> _dragUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 16 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -250));
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

  testWidgets('Task 19 opens PIN verification from active delivery',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository:
              const DemoDriverDeliveryDestinationRepository(),
          pinRepository: DemoDriverDeliveryPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final arrived = find.widgetWithText(FilledButton, 'Arrived at Customer');
    await _dragUntilBuilt(tester, arrived);
    await tester.tap(arrived);
    await tester.pumpAndSettle();

    final enterCode = find.text('Enter Delivery Code');
    await _dragUntilBuilt(tester, enterCode);
    await tester.tap(enterCode);
    await tester.pumpAndSettle();

    expect(find.text('Delivery Verification'), findsOneWidget);
    expect(find.text('Ask customer for their delivery code'), findsOneWidget);
  });
}
