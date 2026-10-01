import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/recovery/data/driver_runtime_recovery_store.dart';

void main() {
  test('Task 122 recovery snapshot preserves Laravel numeric order id', () {
    const delivery = DriverActiveDeliverySummary(
      apiOrderId: 77,
      orderNumber: 'GETIN-77',
      status: 'out_for_delivery',
      pickupBranch: 'Branch',
      destinationArea: 'Area',
      etaMinutes: 0,
    );
    const snapshot = DriverRuntimeRecoverySnapshot(activeDelivery: delivery);
    expect(snapshot.activeDelivery?.apiOrderId, 77);
  });
}
