import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_qr_models.dart';
import 'package:getin_driver/features/delivery_verification/driver_delivery_qr_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-UAT-9001',
    status: 'Verification pending',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  test('Task 253 restores the same successful demo QR receipt idempotently',
      () async {
    final repository = DemoDriverDeliveryQrRepository();
    final firstLoad = await repository.loadChallenge(
      apiOrderId: null,
      orderNumber: delivery.orderNumber,
    );
    final challenge = firstLoad.challenge!;

    final first = await repository.verifyQr(
      apiOrderId: null,
      challenge: challenge,
      orderNumber: delivery.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );
    expect(first.isSuccess, isTrue);

    final restored = await repository.loadChallenge(
      apiOrderId: null,
      orderNumber: delivery.orderNumber,
    );
    expect(restored.verifiedReceipt?.auditId, first.receipt?.auditId);
    expect(restored.verifiedReceipt?.verificationType, 'qr');

    final repeated = await repository.verifyQr(
      apiOrderId: null,
      challenge: restored.challenge!,
      orderNumber: delivery.orderNumber,
      customerReference: restored.challenge!.customerReference,
      assignedDriverReference: restored.challenge!.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );
    expect(repeated.isSuccess, isTrue);
    expect(repeated.receipt?.auditId, first.receipt?.auditId);
  });

  test('Task 253 still rejects a consumed QR with no matching receipt',
      () async {
    final repository = DemoDriverDeliveryQrRepository();
    final load = await repository.loadChallenge(
      apiOrderId: null,
      orderNumber: delivery.orderNumber,
    );
    final original = load.challenge!;
    final consumed = DriverDeliveryQrChallenge(
      orderNumber: original.orderNumber,
      customerReference: original.customerReference,
      assignedDriverReference: original.assignedDriverReference,
      expiresAt: original.expiresAt,
      usedAt: DateTime.now(),
    );

    final result = await repository.verifyQr(
      apiOrderId: null,
      challenge: consumed,
      orderNumber: delivery.orderNumber,
      customerReference: consumed.customerReference,
      assignedDriverReference: consumed.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, DriverDeliveryQrFailureReason.alreadyUsed);
  });

  testWidgets(
      'Task 253 app-bar back returns successful QR receipt and reopen restores success',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = DemoDriverDeliveryQrRepository();
    DriverDeliveryQrScreenOutcome? returned;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                returned = await Navigator.of(context)
                    .push<DriverDeliveryQrScreenOutcome>(
                  MaterialPageRoute<DriverDeliveryQrScreenOutcome>(
                    builder: (_) => DriverDeliveryQrScreen(
                      config: config,
                      delivery: delivery,
                      repository: repository,
                    ),
                  ),
                );
              },
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();
    final scan = find.widgetWithText(FilledButton, 'Simulate Customer QR Scan');
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();
    expect(find.text('QR VERIFIED'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(returned?.receipt?.verificationType, 'qr');

    returned = null;
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();
    expect(find.text('QR VERIFIED'), findsOneWidget);
    expect(find.text('Delivery Verified'), findsOneWidget);
    expect(find.text('QR already used'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(returned?.receipt?.verificationType, 'qr');
  });
}
