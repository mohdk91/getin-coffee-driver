enum DriverVehicleDataSource { demo, api }

enum DriverVehicleField {
  vehicleType('Vehicle type'),
  plate('Plate'),
  makeModel('Make / model'),
  color('Color');

  final String label;
  const DriverVehicleField(this.label);
}

enum DriverVehicleStatus {
  active('Active'),
  inactive('Inactive'),
  pendingApproval('Pending approval'),
  suspended('Suspended');

  final String label;
  const DriverVehicleStatus(this.label);
}

enum DriverVehicleDocumentStatus {
  valid('Valid'),
  expiringSoon('Expiring soon'),
  pendingReview('Pending review'),
  expired('Expired'),
  rejected('Rejected');

  final String label;
  const DriverVehicleDocumentStatus(this.label);
}

class DriverVehicleSnapshot {
  final String vehicleType;
  final String plate;
  final String makeModel;
  final String color;
  final DriverVehicleStatus status;
  final DriverVehicleDocumentStatus documentStatus;
  final Set<DriverVehicleField> editableFields;
  final DateTime updatedAt;

  const DriverVehicleSnapshot({
    required this.vehicleType,
    required this.plate,
    required this.makeModel,
    required this.color,
    required this.status,
    required this.documentStatus,
    required this.editableFields,
    required this.updatedAt,
  });

  bool canEdit(DriverVehicleField field) => editableFields.contains(field);

  bool get hasEditableFields => editableFields.isNotEmpty;

  DriverVehicleSnapshot copyWith({
    String? vehicleType,
    String? plate,
    String? makeModel,
    String? color,
    DriverVehicleStatus? status,
    DriverVehicleDocumentStatus? documentStatus,
    Set<DriverVehicleField>? editableFields,
    DateTime? updatedAt,
  }) {
    return DriverVehicleSnapshot(
      vehicleType: vehicleType ?? this.vehicleType,
      plate: plate ?? this.plate,
      makeModel: makeModel ?? this.makeModel,
      color: color ?? this.color,
      status: status ?? this.status,
      documentStatus: documentStatus ?? this.documentStatus,
      editableFields: editableFields ?? this.editableFields,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DriverVehicleUpdateRequest {
  final String vehicleType;
  final String plate;
  final String makeModel;
  final String color;

  const DriverVehicleUpdateRequest({
    required this.vehicleType,
    required this.plate,
    required this.makeModel,
    required this.color,
  });
}

class DriverVehicleLoadResult {
  final DriverVehicleSnapshot? vehicle;
  final String? errorMessage;

  const DriverVehicleLoadResult._({this.vehicle, this.errorMessage});

  const DriverVehicleLoadResult.success(DriverVehicleSnapshot value)
      : this._(vehicle: value);

  const DriverVehicleLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => vehicle != null;
}

class DriverVehicleUpdateResult {
  final DriverVehicleSnapshot? vehicle;
  final String? errorMessage;

  const DriverVehicleUpdateResult._({this.vehicle, this.errorMessage});

  const DriverVehicleUpdateResult.success(DriverVehicleSnapshot value)
      : this._(vehicle: value);

  const DriverVehicleUpdateResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => vehicle != null;
}
