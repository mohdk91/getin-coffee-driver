import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';
import 'package:getin_driver/features/delivery_verification/driver_delivery_qr_screen.dart';
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

  testWidgets('Task 20 QR screen offers QR scan plus PIN fallback',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryQrScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverDeliveryQrRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan the customer delivery QR'), findsOneWidget);
    expect(find.text('Simulate Customer QR Scan'), findsOneWidget);
    expect(find.textContaining('same secure handoff verification'),
        findsOneWidget);

    // The PIN fallback sits below the initially built portion of the lazy
    // ListView on smaller test surfaces. Scroll the QR screen before checking
    // that control so the test matches real user behavior.
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Enter Code Instead'), findsOneWidget);
  });

  testWidgets('Task 20 demo QR verifies without marking order delivered',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryQrScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverDeliveryQrRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scan = find.widgetWithText(FilledButton, 'Simulate Customer QR Scan');
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();

    expect(find.text('Delivery Verified'), findsOneWidget);
    expect(find.textContaining('Laravel has not acknowledged'), findsOneWidget);
    expect(
        find.textContaining('order is not marked Delivered'), findsOneWidget);
    expect(find.text('Back to Delivery'), findsOneWidget);
    expect(find.text('Complete Delivery'), findsNothing);
  });
}
