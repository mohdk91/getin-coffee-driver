enum DriverRegistrationSource { demo, unavailable }

enum DriverRegistrationFailureType {
  invalidInput,
  temporaryFailure,
  unavailable,
}

class DriverRegistrationFailure {
  final DriverRegistrationFailureType type;
  final String message;
  final bool retryable;

  const DriverRegistrationFailure({
    required this.type,
    required this.message,
    this.retryable = false,
  });
}

class DriverRegistrationResult<T> {
  final T? data;
  final DriverRegistrationFailure? failure;

  const DriverRegistrationResult.success(T value)
      : data = value,
        failure = null;

  const DriverRegistrationResult.failure(DriverRegistrationFailure value)
      : data = null,
        failure = value;

  bool get isSuccess => data != null && failure == null;
}

enum DriverVehicleType {
  motorbike('Motorbike'),
  car('Car'),
  scooter('Scooter'),
  bicycle('Bicycle');

  final String label;
  const DriverVehicleType(this.label);
}

enum DriverRegistrationDocumentType {
  nationalId('National ID', 'Front or clear identity document'),
  drivingLicense('Driving licence', 'Valid driving licence'),
  vehicleDocument('Vehicle document', 'Registration or ownership document');

  final String label;
  final String helper;
  const DriverRegistrationDocumentType(this.label, this.helper);
}

class DriverRegistrationDraft {
  final String fullName;
  final String dateOfBirth;
  final String dialCode;
  final String phoneNumber;
  final String email;
  final String nationalId;
  final String drivingLicenseNumber;
  final String drivingLicenseExpiry;
  final DriverVehicleType vehicleType;
  final String vehicleMakeModel;
  final String plateNumber;
  final String vehicleColor;
  final Set<DriverRegistrationDocumentType> documents;
  final String country;
  final String city;
  final String region;
  final String preferredBranch;
  final bool acceptedDeclaration;

  const DriverRegistrationDraft({
    required this.fullName,
    required this.dateOfBirth,
    required this.dialCode,
    required this.phoneNumber,
    required this.email,
    required this.nationalId,
    required this.drivingLicenseNumber,
    required this.drivingLicenseExpiry,
    required this.vehicleType,
    required this.vehicleMakeModel,
    required this.plateNumber,
    required this.vehicleColor,
    required this.documents,
    required this.country,
    required this.city,
    required this.region,
    required this.preferredBranch,
    required this.acceptedDeclaration,
  });

  bool get hasRequiredDocuments =>
      DriverRegistrationDocumentType.values.every(documents.contains);
}

class DriverRegistrationReceipt {
  final String applicationId;
  final String statusLabel;
  final DateTime submittedAt;

  const DriverRegistrationReceipt({
    required this.applicationId,
    required this.statusLabel,
    required this.submittedAt,
  });
}
