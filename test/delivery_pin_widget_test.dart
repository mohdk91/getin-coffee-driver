import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/driver_delivery_pin_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-2481',
    status: 'Out for delivery • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  testWidgets('Task 19 keeps delivery incomplete before PIN verification',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryPinScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverDeliveryPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ask customer for their delivery code'), findsOneWidget);
    expect(find.textContaining('Use PIN 4821'), findsOneWidget);
    expect(find.text('Verify Delivery'), findsOneWidget);
    expect(find.text('Delivery Verified'), findsNothing);
    expect(
        find.textContaining('Complete Delivery stays locked'), findsOneWidget);
  });

  testWidgets('Task 19 demo PIN verifies without marking order delivered',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryPinScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverDeliveryPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '4821');
    final verify = find.widgetWithText(FilledButton, 'Verify Delivery');
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(find.text('Delivery Verified'), findsOneWidget);
    expect(find.textContaining('Laravel has not acknowledged'), findsOneWidget);
    expect(
        find.textContaining('order is not marked Delivered'), findsOneWidget);
    expect(find.text('Back to Delivery'), findsOneWidget);
    expect(find.text('Complete Delivery'), findsNothing);
  });

  testWidgets('Task 19 rejects malformed code before repository verification',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryPinScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverDeliveryPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify Delivery'));
    await tester.pump();

    expect(
        find.text('Enter the complete 4-digit delivery code.'), findsOneWidget);
    expect(find.text('Delivery Verified'), findsNothing);
  });
}
