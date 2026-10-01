import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/eligibility/domain/driver_order_eligibility_models.dart';

void main() {
  test('Task 107 order candidate can retain Laravel offer and order ids', () {
    const order = DriverOrderCandidate(
      apiOrderId: 91,
      apiOfferId: 44,
      orderNumber: 'GD-91',
      pickupBranch: 'Stanley',
      region: 'East Alexandria',
      zone: 'East Alexandria',
      destinationArea: 'Gleem',
      distanceToBranchKm: 0,
      deliveryDistanceKm: 0,
      allowedVehicleTypes: <String>[],
      isAvailable: true,
    );

    expect(order.apiOrderId, 91);
    expect(order.apiOfferId, 44);
  });
}
