import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test('Task 115 customer arrival remains tied to Laravel order id', () {
    const delivery = DriverActiveDeliverySummary(
        apiOrderId: 91,
        orderNumber: 'GD-91',
        status: 'Out for delivery',
        pickupBranch: 'Stanley',
        destinationArea: 'Gleem',
        etaMinutes: 8);
    expect(delivery.apiOrderId, 91);
  });
}
