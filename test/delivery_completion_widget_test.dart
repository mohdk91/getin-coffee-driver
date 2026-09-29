import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_completion/data/driver_delivery_completion_repository.dart';
import 'package:getin_driver/features/delivery_completion/domain/driver_delivery_completion_models.dart';
import 'package:getin_driver/features/delivery_completion/driver_complete_delivery_card.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

const delivery = DriverActiveDeliverySummary(
  orderNumber: 'GD-2481',
  status: 'Out for delivery • Demo',
  pickupBranch: 'Stanley',
  destinationArea: 'San Stefano',
  etaMinutes: 19,
);

DriverDeliveryPinReceipt _verification() {
  return DriverDeliveryPinReceipt(
    auditId: 'VERIFY-1',
    orderNumber: 'GD-2481',
    customerReference: 'DEMO-CUSTOMER-GD-2481',
    assignedDriverReference: 'DEMO-DRIVER-001',
    verifiedAt: DateTime(2026, 9, 26, 10),
    verificationType: 'qr',
    serverAcknowledged: false,
    isDemo: true,
  );
}

void main() {
  testWidgets('Task 22 keeps Complete Delivery locked before verification',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverCompleteDeliveryCard(
            delivery: delivery,
            verification: null,
            repository: DemoDriverDeliveryCompletionRepository(),
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Complete Delivery'),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('verification is required'), findsOneWidget);
  });

  testWidgets('Task 22 verified delivery can complete locally in development',
      (tester) async {
    DriverDeliveryCompletionReceipt? completed;

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverCompleteDeliveryCard(
              delivery: delivery,
              verification: _verification(),
              repository: const DemoDriverDeliveryCompletionRepository(),
              onCompleted: (value) => completed = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Complete Delivery'));
    await tester.pumpAndSettle();

    expect(completed, isNotNull);
    expect(find.text('Delivery Completed'), findsOneWidget);
    expect(find.text('DELIVERED • DEMO'), findsOneWidget);
    expect(find.textContaining('Laravel and the Customer App were not updated'),
        findsOneWidget);
    expect(find.text('Back to Driver Home'), findsOneWidget);
  });

  testWidgets('Task 22 backend failure keeps order unchanged and retryable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverCompleteDeliveryCard(
              delivery: delivery,
              verification: _verification(),
              repository: const UnavailableDriverDeliveryCompletionRepository(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Complete Delivery'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not confirm with Getin. Your order status has not changed. Retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Delivery Completed'), findsNothing);
    expect(
        find.widgetWithText(FilledButton, 'Complete Delivery'), findsOneWidget);
  });
}
