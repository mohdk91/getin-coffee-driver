import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  test('Task 110 active delivery retains API id for branch movement', () {
    const delivery = DriverActiveDeliverySummary(
      apiOrderId: 91,
      orderNumber: 'GD-91',
      status: 'Accepted',
      pickupBranch: 'Stanley',
      destinationArea: 'Gleem',
      etaMinutes: 8,
    );
    expect(delivery.apiOrderId, 91);
  });
}
