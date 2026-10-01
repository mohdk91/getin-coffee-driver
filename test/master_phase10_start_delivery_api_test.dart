import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test('Task 113 start-delivery flow keeps server order id', () {
    const delivery = DriverActiveDeliverySummary(
      apiOrderId: 91,
      orderNumber: 'GD-91',
      status: 'Picked up',
      pickupBranch: 'Stanley',
      destinationArea: 'Gleem',
      etaMinutes: 8,
    );
    expect(delivery.apiOrderId, 91);
  });
}
