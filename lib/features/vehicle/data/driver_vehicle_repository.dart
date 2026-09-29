import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_vehicle_models.dart';

abstract interface class DriverVehicleRepository {
  DriverVehicleDataSource get source;

  Future<DriverVehicleLoadResult> loadVehicle();

  Future<DriverVehicleUpdateResult> updateVehicle(
    DriverVehicleUpdateRequest request,
  );
}

class DriverVehicleRepositoryFactory {
  DriverVehicleRepositoryFactory._();

  static DriverVehicleRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? DemoDriverVehicleRepository()
        : const UnavailableDriverVehicleRepository();
  }
}

class DemoDriverVehicleRepository implements DriverVehicleRepository {
  DriverVehicleSnapshot _vehicle = DriverVehicleSnapshot(
    vehicleType: 'Motorcycle',
    plate: 'ALEX-2417',
    makeModel: 'Honda PCX 160',
    color: 'Black',
    status: DriverVehicleStatus.active,
    documentStatus: DriverVehicleDocumentStatus.valid,
    editableFields: const {
      DriverVehicleField.makeModel,
      DriverVehicleField.color,
    },
    updatedAt: DateTime(2026, 9, 26),
  );

  @override
  DriverVehicleDataSource get source => DriverVehicleDataSource.demo;

  @override
  Future<DriverVehicleLoadResult> loadVehicle() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return DriverVehicleLoadResult.success(_vehicle);
  }

  @override
  Future<DriverVehicleUpdateResult> updateVehicle(
    DriverVehicleUpdateRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final deniedField = _firstDeniedChange(request);
    if (deniedField != null) {
      return DriverVehicleUpdateResult.failure(
        '${deniedField.label} is managed by Getin and cannot be changed in the Driver App.',
      );
    }

    if (request.vehicleType.trim().isEmpty ||
        request.plate.trim().isEmpty ||
        request.makeModel.trim().isEmpty ||
        request.color.trim().isEmpty) {
      return const DriverVehicleUpdateResult.failure(
        'Vehicle fields cannot be empty.',
      );
    }

    _vehicle = _vehicle.copyWith(
      vehicleType: request.vehicleType.trim(),
      plate: request.plate.trim(),
      makeModel: request.makeModel.trim(),
      color: request.color.trim(),
      updatedAt: DateTime.now(),
    );

    return DriverVehicleUpdateResult.success(_vehicle);
  }

  DriverVehicleField? _firstDeniedChange(DriverVehicleUpdateRequest request) {
    final candidates = <DriverVehicleField, bool>{
      DriverVehicleField.vehicleType:
          request.vehicleType.trim() != _vehicle.vehicleType,
      DriverVehicleField.plate: request.plate.trim() != _vehicle.plate,
      DriverVehicleField.makeModel:
          request.makeModel.trim() != _vehicle.makeModel,
      DriverVehicleField.color: request.color.trim() != _vehicle.color,
    };

    for (final entry in candidates.entries) {
      if (entry.value && !_vehicle.canEdit(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }
}

class UnavailableDriverVehicleRepository implements DriverVehicleRepository {
  const UnavailableDriverVehicleRepository();

  @override
  DriverVehicleDataSource get source => DriverVehicleDataSource.api;

  @override
  Future<DriverVehicleLoadResult> loadVehicle() async {
    return const DriverVehicleLoadResult.failure(
      'Vehicle data is not connected to the Laravel API yet. Getin will not invent production vehicle, status or document information.',
    );
  }

  @override
  Future<DriverVehicleUpdateResult> updateVehicle(
    DriverVehicleUpdateRequest request,
  ) async {
    return const DriverVehicleUpdateResult.failure(
      'Vehicle updates require the Laravel API.',
    );
  }
}
