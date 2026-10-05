import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/incoming_orders/driver_incoming_order_capacity.dart';

void main() {
  test('Task 247 allows an idle driver to receive a broadcast offer', () {
    const capacity = DriverIncomingOrderCapacity(activeOrderCount: 0);

    expect(capacity.canReceiveOffer, isTrue);
  });

  test('Task 247 blocks a second order when active capacity is full', () {
    const capacity = DriverIncomingOrderCapacity(activeOrderCount: 1);

    expect(capacity.canReceiveOffer, isFalse);
    expect(
      capacity.blockedMessage,
      'Finish your active delivery before receiving another order.',
    );
  });
}
