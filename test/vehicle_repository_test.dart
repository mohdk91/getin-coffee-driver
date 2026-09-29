import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/vehicle/data/driver_vehicle_repository.dart';
import 'package:getin_driver/features/vehicle/domain/driver_vehicle_models.dart';

void main() {
  test('Task 33 demo repository exposes all required vehicle fields', () async {
    final repository = DemoDriverVehicleRepository();

    final result = await repository.loadVehicle();

    expect(result.isSuccess, isTrue);
    expect(repository.source, DriverVehicleDataSource.demo);
    expect(result.vehicle!.vehicleType, 'Motorcycle');
    expect(result.vehicle!.plate, 'ALEX-2417');
    expect(result.vehicle!.makeModel, 'Honda PCX 160');
    expect(result.vehicle!.color, 'Black');
    expect(result.vehicle!.status, DriverVehicleStatus.active);
    expect(
      result.vehicle!.documentStatus,
      DriverVehicleDocumentStatus.valid,
    );
  });

  test('Task 33 updates only fields explicitly permitted by Getin', () async {
    final repository = DemoDriverVehicleRepository();

    final allowed = await repository.updateVehicle(
      const DriverVehicleUpdateRequest(
        vehicleType: 'Motorcycle',
        plate: 'ALEX-2417',
        makeModel: 'Honda PCX 160 ABS',
        color: 'Pearl Black',
      ),
    );

    expect(allowed.isSuccess, isTrue);
    expect(allowed.vehicle!.makeModel, 'Honda PCX 160 ABS');
    expect(allowed.vehicle!.color, 'Pearl Black');

    final denied = await repository.updateVehicle(
      const DriverVehicleUpdateRequest(
        vehicleType: 'Car',
        plate: 'ALEX-2417',
        makeModel: 'Honda PCX 160 ABS',
        color: 'Pearl Black',
      ),
    );

    expect(denied.isSuccess, isFalse);
    expect(denied.errorMessage, contains('Vehicle type'));
  });

  test('Task 33 unavailable repository never invents production vehicle',
      () async {
    const repository = UnavailableDriverVehicleRepository();

    final result = await repository.loadVehicle();

    expect(repository.source, DriverVehicleDataSource.api);
    expect(result.isSuccess, isFalse);
    expect(result.vehicle, isNull);
    expect(result.errorMessage, contains('Laravel API'));
  });
}
