import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';

void main() {
  test('Task 19 demo PIN validates order customer driver code and one-time use',
      () async {
    final repository = DemoDriverDeliveryPinRepository();
    final load = await repository.loadChallenge(orderNumber: 'GD-2481');
    final challenge = load.challenge!;

    final success = await repository.verifyPin(
      challenge: challenge,
      orderNumber: 'GD-2481',
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );

    expect(success.isSuccess, isTrue);
    expect(success.receipt?.verificationType, 'pin');
    expect(success.receipt?.serverAcknowledged, isFalse);
    expect(success.receipt?.isDemo, isTrue);

    final reused = await repository.verifyPin(
      challenge: challenge,
      orderNumber: 'GD-2481',
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );

    expect(reused.isSuccess, isFalse);
    expect(
      reused.failureReason,
      DriverDeliveryPinFailureReason.alreadyUsed,
    );
  });

  test('Task 19 rejects wrong assigned driver binding', () async {
    final repository = DemoDriverDeliveryPinRepository();
    final load = await repository.loadChallenge(orderNumber: 'GD-2481');
    final challenge = load.challenge!;

    final result = await repository.verifyPin(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: 'ANOTHER-DRIVER',
      code: DemoDriverDeliveryPinRepository.demoCode,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, DriverDeliveryPinFailureReason.wrongDriver);
  });

  test('Task 19 rejects expired challenge', () async {
    final repository = DemoDriverDeliveryPinRepository();
    final challenge = DriverDeliveryPinChallenge(
      orderNumber: 'GD-2481',
      customerReference: 'DEMO-CUSTOMER-GD-2481',
      assignedDriverReference: 'DEMO-DRIVER-001',
      codeLength: 4,
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final result = await repository.verifyPin(
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: DemoDriverDeliveryPinRepository.demoCode,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, DriverDeliveryPinFailureReason.expired);
  });

  test('Task 19 production repository never fakes a verification', () async {
    const repository = UnavailableDriverDeliveryPinRepository();
    final load = await repository.loadChallenge(orderNumber: 'GD-2481');

    expect(load.isSuccess, isFalse);
    expect(load.errorMessage, contains('will not invent'));
  });
}
