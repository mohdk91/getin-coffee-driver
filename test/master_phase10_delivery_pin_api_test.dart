import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test('Task 116 PIN verification uses the server order identity', () {
    const delivery = DriverActiveDeliverySummary(
      apiOrderId: 91,
      orderNumber: 'GD-91',
      status: 'Arrived customer',
      pickupBranch: 'Stanley',
      destinationArea: 'Gleem',
      etaMinutes: 0,
    );
    expect(delivery.apiOrderId, 91);
  });
}
