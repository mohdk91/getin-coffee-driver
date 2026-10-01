import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_qr_models.dart';

void main() {
  test('Task 20 demo QR verifies the same delivery handoff concept', () async {
    final repository = DemoDriverDeliveryQrRepository();
    final load = await repository.loadChallenge(
        apiOrderId: null, orderNumber: 'GD-2481');
    final challenge = load.challenge!;

    final result = await repository.verifyQr(
      apiOrderId: null,
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );

    expect(result.isSuccess, isTrue);
    expect(result.receipt?.verificationType, 'qr');
    expect(result.receipt?.orderNumber, 'GD-2481');
    expect(result.receipt?.serverAcknowledged, isFalse);
    expect(result.receipt?.isDemo, isTrue);
  });

  test('Task 20 demo QR is one-time within its verification repository',
      () async {
    final repository = DemoDriverDeliveryQrRepository();
    final load = await repository.loadChallenge(
        apiOrderId: null, orderNumber: 'GD-2481');
    final challenge = load.challenge!;

    await repository.verifyQr(
      apiOrderId: null,
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );

    final reused = await repository.verifyQr(
      apiOrderId: null,
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );

    expect(reused.isSuccess, isFalse);
    expect(reused.failureReason, DriverDeliveryQrFailureReason.alreadyUsed);
  });

  test('Task 20 rejects QR bound to another assigned driver', () async {
    final repository = DemoDriverDeliveryQrRepository();
    final load = await repository.loadChallenge(
        apiOrderId: null, orderNumber: 'GD-2481');
    final challenge = load.challenge!;

    final result = await repository.verifyQr(
      apiOrderId: null,
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: 'ANOTHER-DRIVER',
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, DriverDeliveryQrFailureReason.wrongDriver);
  });

  test('Task 20 production QR repository never fakes verification', () async {
    const repository = UnavailableDriverDeliveryQrRepository();
    final result = await repository.loadChallenge(
        apiOrderId: null, orderNumber: 'GD-2481');

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('will not invent'));
  });
}
