import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/vehicle/domain/driver_vehicle_models.dart';

void main() {
  test('Phase 9 vehicle edit policy keeps identity fields server managed', () {
    const fields = {DriverVehicleField.makeModel, DriverVehicleField.color};
    expect(fields, isNot(contains(DriverVehicleField.plate)));
  });
}
