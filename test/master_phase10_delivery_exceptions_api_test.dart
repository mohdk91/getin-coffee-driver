import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_exceptions/domain/driver_delivery_exception_models.dart';

void main() {
  test('Task 121 exception reasons remain explicit and auditable', () {
    expect(DriverDeliveryExceptionReason.values.length, 8);
    expect(DriverDeliveryExceptionReason.safetyIssue.label, 'Safety issue');
  });
}
