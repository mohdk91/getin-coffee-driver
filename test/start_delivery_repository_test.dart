import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery/data/driver_start_delivery_repository.dart';

void main() {
  test('Task 15 demo start delivery returns local non-server receipt',
      () async {
    const repository = DemoDriverStartDeliveryRepository();

    final result = await repository.startDelivery(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      latitude: 31.2458,
      longitude: 29.9668,
    );

    expect(result.isSuccess, isTrue);
    expect(result.receipt, isNotNull);
    expect(result.receipt!.orderNumber, 'GD-2481');
    expect(result.receipt!.isDemo, isTrue);
    expect(result.receipt!.serverAcknowledged, isFalse);
  });

  test('Task 15 non-development repository never fakes start delivery',
      () async {
    const repository = UnavailableDriverStartDeliveryRepository();

    final result = await repository.startDelivery(
      apiOrderId: null,
      orderNumber: 'GD-2481',
      latitude: 31.2458,
      longitude: 29.9668,
    );

    expect(result.isSuccess, isFalse);
    expect(result.receipt, isNull);
    expect(result.errorMessage, contains('status has not changed'));
  });
}
