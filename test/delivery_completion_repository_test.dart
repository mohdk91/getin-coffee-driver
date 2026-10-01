import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_completion/data/driver_delivery_completion_repository.dart';
import 'package:getin_driver/features/delivery_completion/domain/driver_delivery_completion_models.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';

DriverDeliveryPinReceipt _verification({String orderNumber = 'GD-2481'}) {
  return DriverDeliveryPinReceipt(
    auditId: 'VERIFY-1',
    orderNumber: orderNumber,
    customerReference: 'DEMO-CUSTOMER-$orderNumber',
    assignedDriverReference: 'DEMO-DRIVER-001',
    verifiedAt: DateTime(2026, 9, 26, 10),
    verificationType: 'pin',
    serverAcknowledged: false,
    isDemo: true,
  );
}

void main() {
  test('Task 22 demo completion records delivered audit fields', () async {
    const repository = DemoDriverDeliveryCompletionRepository();

    final result = await repository.completeDelivery(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      verification: _verification(),
    );

    expect(result.isSuccess, isTrue);
    expect(result.receipt?.orderState, 'delivered');
    expect(result.receipt?.driverReference, 'DEMO-DRIVER-001');
    expect(result.receipt?.verificationType, 'pin');
    expect(result.receipt?.latitude, isNotNull);
    expect(result.receipt?.longitude, isNotNull);
    expect(result.receipt?.serverTimestamp, isNull);
    expect(result.receipt?.serverAcknowledged, isFalse);
    expect(result.receipt?.isDemo, isTrue);
  });

  test('Task 22 rejects verification from another order', () async {
    const repository = DemoDriverDeliveryCompletionRepository();

    final result = await repository.completeDelivery(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      verification: _verification(orderNumber: 'GD-9999'),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      DriverDeliveryCompletionFailureReason.verificationMismatch,
    );
    expect(result.message, contains('status has not changed'));
  });

  test('Task 22 unavailable backend never fakes Delivered', () async {
    const repository = UnavailableDriverDeliveryCompletionRepository();

    final result = await repository.completeDelivery(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      verification: _verification(),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      DriverDeliveryCompletionFailureReason.unavailable,
    );
    expect(
      result.message,
      'Could not confirm with Getin. Your order status has not changed. Retry.',
    );
  });
}
