import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_qr_models.dart';
import 'package:getin_driver/features/delivery_verification/driver_delivery_pin_screen.dart';
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

  test('Task 21 PIN supports invalid, wrong-order and too-many-attempt states',
      () async {
    final repository = DemoDriverDeliveryPinRepository();
    final challenge =
        (await repository.loadChallenge(orderNumber: 'GD-2481')).challenge!;

    final invalid = await repository.verifyPin(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: '1111',
    );
    expect(invalid.failureReason, DriverDeliveryPinFailureReason.invalidCode);

    final wrongOrder = await repository.verifyPin(
      challenge: challenge,
      orderNumber: 'GD-9999',
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );
    expect(wrongOrder.failureReason, DriverDeliveryPinFailureReason.wrongOrder);

    await repository.verifyPin(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: '2222',
    );
    final locked = await repository.verifyPin(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: '3333',
    );
    expect(
      locked.failureReason,
      DriverDeliveryPinFailureReason.tooManyAttempts,
    );
    expect(locked.message, contains('Delivery remains locked'));
  });

  test('Task 21 PIN preserves expired and already-used safety states',
      () async {
    final repository = DemoDriverDeliveryPinRepository();
    final expiredChallenge = DriverDeliveryPinChallenge(
      orderNumber: 'GD-2481',
      customerReference: 'DEMO-CUSTOMER-GD-2481',
      assignedDriverReference: 'DEMO-DRIVER-001',
      codeLength: 4,
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final expired = await repository.verifyPin(
      challenge: expiredChallenge,
      orderNumber: expiredChallenge.orderNumber,
      customerReference: expiredChallenge.customerReference,
      assignedDriverReference: expiredChallenge.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );
    expect(expired.failureReason, DriverDeliveryPinFailureReason.expired);

    final live =
        (await repository.loadChallenge(orderNumber: 'GD-3199')).challenge!;
    await repository.verifyPin(
      challenge: live,
      orderNumber: live.orderNumber,
      customerReference: live.customerReference,
      assignedDriverReference: live.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );
    final reused = await repository.verifyPin(
      challenge: live,
      orderNumber: live.orderNumber,
      customerReference: live.customerReference,
      assignedDriverReference: live.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );
    expect(reused.failureReason, DriverDeliveryPinFailureReason.alreadyUsed);
  });

  test('Task 21 QR supports invalid and too-many-attempt states', () async {
    final repository = DemoDriverDeliveryQrRepository();
    final challenge =
        (await repository.loadChallenge(orderNumber: 'GD-2481')).challenge!;

    final first = await repository.verifyQr(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: 'BAD-QR-1',
    );
    expect(first.failureReason, DriverDeliveryQrFailureReason.invalidQr);

    await repository.verifyQr(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: 'BAD-QR-2',
    );
    final locked = await repository.verifyQr(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: 'BAD-QR-3',
    );
    expect(locked.failureReason, DriverDeliveryQrFailureReason.tooManyAttempts);
  });

  testWidgets('Task 21 invalid PIN stays unverified and exposes retry guidance',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
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

    await tester.enterText(find.byType(TextField), '1111');
    final verify = find.widgetWithText(FilledButton, 'Verify Delivery');
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(find.text('Invalid code'), findsOneWidget);
    expect(find.text('Try Code Again'), findsOneWidget);
    expect(find.text('Delivery Verified'), findsNothing);
    expect(find.text('Complete Delivery'), findsNothing);
  });

  testWidgets(
      'Task 21 customer-can-not-find-code help never bypasses verification',
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

    final help = find.text("Customer can't find the code");
    for (var i = 0; i < 5 && help.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    expect(help, findsOneWidget);
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Verification is still required'), findsOneWidget);
    expect(find.textContaining('Scan Customer QR'), findsOneWidget);
    expect(find.text('Delivery Verified'), findsNothing);
    expect(find.text('Complete Delivery'), findsNothing);
  });

  testWidgets('Task 21 camera unavailable offers retry and PIN fallback',
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

    final unavailable =
        find.widgetWithText(OutlinedButton, 'Simulate Camera Unavailable');
    await tester.ensureVisible(unavailable);
    await tester.tap(unavailable);
    await tester.pumpAndSettle();

    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(find.text('Retry Camera'), findsOneWidget);
    expect(find.text('Enter Code Instead'), findsWidgets);
    expect(find.text('Delivery Verified'), findsNothing);
    expect(find.text('Complete Delivery'), findsNothing);
  });
}
