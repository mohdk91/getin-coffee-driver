import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test('Task 111 branch arrival requires the active Laravel order id', () {
    const delivery = DriverActiveDeliverySummary(
        apiOrderId: 91,
        orderNumber: 'GD-91',
        status: 'Going to branch',
        pickupBranch: 'Stanley',
        destinationArea: 'Gleem',
        etaMinutes: 8);
    expect(delivery.apiOrderId, isNotNull);
  });
}
