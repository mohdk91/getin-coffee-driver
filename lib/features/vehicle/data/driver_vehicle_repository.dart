import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
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

  static DriverVehicleRepository create(AppConfig config,
      {DriverApiContext? context}) {
    if (config.isApiConfigured) {
      return ApiDriverVehicleRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.environment == AppEnvironment.development
        ? DemoDriverVehicleRepository()
        : const UnavailableDriverVehicleRepository();
  }
}

class ApiDriverVehicleRepository implements DriverVehicleRepository {
  final DriverApiContext context;
  Map<String, dynamic>? _raw;
  ApiDriverVehicleRepository(this.context);
  @override
  DriverVehicleDataSource get source => DriverVehicleDataSource.api;
  @override
  Future<DriverVehicleLoadResult> loadVehicle() async {
    try {
      final items = DriverApiContext.nestedItems(await context.apiClient
          .getJson('/v1/driver/vehicles', authenticated: true));
      final maps = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (maps.isEmpty) {
        return const DriverVehicleLoadResult.failure(
          'No vehicle is registered for this driver account.',
        );
      }
      _raw = maps.firstWhere((e) => e['is_primary'] == true,
          orElse: () => maps.first);
      return DriverVehicleLoadResult.success(_map(_raw!));
    } on ApiException catch (e) {
      return DriverVehicleLoadResult.failure(e.message);
    } on FormatException catch (e) {
      return DriverVehicleLoadResult.failure(e.message);
    }
  }

  @override
  Future<DriverVehicleUpdateResult> updateVehicle(
      DriverVehicleUpdateRequest request) async {
    final raw = _raw;
    final id = raw?['id'];
    if (id == null) {
      return const DriverVehicleUpdateResult.failure(
        'Reload vehicle data before saving changes.',
      );
    }
    final currentMake = raw?['make']?.toString() ?? '';
    final combined = request.makeModel.trim();
    var make = currentMake;
    var model = combined;
    if (currentMake.isNotEmpty &&
        combined.toLowerCase().startsWith('${currentMake.toLowerCase()} ')) {
      model = combined.substring(currentMake.length).trim();
    }
    try {
      final data = DriverApiContext.dataMap(await context.apiClient.putJson(
          '/v1/driver/vehicles/$id',
          authenticated: true,
          body: <String, Object?>{
            'make': make,
            'model': model,
            'color': request.color.trim()
          }));
      _raw = data;
      return DriverVehicleUpdateResult.success(_map(data));
    } on ApiException catch (e) {
      return DriverVehicleUpdateResult.failure(e.message);
    }
  }

  DriverVehicleSnapshot _map(Map<String, dynamic> data) {
    final make = data['make']?.toString().trim() ?? '';
    final model = data['model']?.toString().trim() ?? '';
    final verification = data['verification_status']?.toString().toLowerCase();
    final documentStatus = switch (verification) {
      'approved' => DriverVehicleDocumentStatus.valid,
      'rejected' => DriverVehicleDocumentStatus.rejected,
      _ => DriverVehicleDocumentStatus.pendingReview
    };
    final active = data['is_active'] == true;
    return DriverVehicleSnapshot(
        vehicleType: data['vehicle_type']?.toString() ?? '',
        plate: data['plate_number']?.toString() ?? '',
        makeModel: [make, model].where((v) => v.isNotEmpty).join(' '),
        color: data['color']?.toString() ?? '',
        status:
            active ? DriverVehicleStatus.active : DriverVehicleStatus.inactive,
        documentStatus: documentStatus,
        editableFields: const {
          DriverVehicleField.makeModel,
          DriverVehicleField.color
        },
        updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
            DateTime.now());
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
