import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';

void main() {
  test('Task 18 demo destination exposes operational handoff fields', () async {
    const repository = DemoDriverDeliveryDestinationRepository();

    final result = await repository.load(orderNumber: 'GD-2481');

    expect(result.isSuccess, isTrue);
    expect(result.destination?.addressLabel, 'Home');
    expect(result.destination?.area, 'San Stefano');
    expect(result.destination?.building, '18');
    expect(result.destination?.floor, '5');
    expect(result.destination?.apartment, '12B');
    expect(result.destination?.latitude, isNotNull);
    expect(result.destination?.longitude, isNotNull);
    expect(result.destination?.deliveryInstructions, isNotEmpty);
  });

  test('Task 18 production repository refuses invented destination', () async {
    const repository = UnavailableDriverDeliveryDestinationRepository();

    final result = await repository.load(orderNumber: 'GD-2481');

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('Laravel API'));
    expect(result.errorMessage, contains('will not invent'));
  });
}
