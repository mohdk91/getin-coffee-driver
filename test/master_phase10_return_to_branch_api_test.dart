import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_exceptions/domain/driver_delivery_exception_models.dart';

void main() {
  test('Task 120 return-to-branch remains a distinct terminal state', () {
    expect(DriverDeliveryExceptionReason.returnToBranch.recommendedOrderState,
        'returned_to_branch');
  });
}
