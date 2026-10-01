import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';
import 'package:getin_driver/features/delivery_exceptions/domain/driver_delivery_exception_models.dart';

void main() {
  setUp(DemoDriverDeliveryExceptionRepository.clearDemoState);

  test('Task 23 demo exception is local and never delivered', () async {
    const repository = DemoDriverDeliveryExceptionRepository();

    final result = await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      reason: DriverDeliveryExceptionReason.customerUnavailable,
      note: 'No response at entrance.',
    );

    expect(result.isSuccess, isTrue);
    expect(result.receipt!.serverAcknowledged, isFalse);
    expect(result.receipt!.isDemo, isTrue);
    expect(result.receipt!.recommendedOrderState, 'failed_delivery');
    expect(result.receipt!.recommendedOrderState, isNot('delivered'));
  });

  test('Task 23 return to branch keeps dedicated recommendation', () async {
    const repository = DemoDriverDeliveryExceptionRepository();

    final result = await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      reason: DriverDeliveryExceptionReason.returnToBranch,
      note: '',
    );

    expect(result.receipt!.recommendedOrderState, 'returned_to_branch');
  });

  test('Task 23 demo report persists for the active order', () async {
    const repository = DemoDriverDeliveryExceptionRepository();
    await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      reason: DriverDeliveryExceptionReason.safetyIssue,
      note: 'Unsafe access point.',
    );

    final restored = await repository.loadActiveException(
      apiOrderId: null,
      orderNumber: 'gd-2481',
    );

    expect(restored, isNotNull);
    expect(restored!.reason, DriverDeliveryExceptionReason.safetyIssue);
  });

  test('Task 23 unavailable backend never fakes acknowledgement', () async {
    const repository = UnavailableDriverDeliveryExceptionRepository();

    final result = await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      reason: DriverDeliveryExceptionReason.wrongAddress,
      note: '',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('order status has not changed'));
  });
}
