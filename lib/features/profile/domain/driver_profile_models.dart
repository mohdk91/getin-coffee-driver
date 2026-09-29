enum DriverProfileDataSource { demo, api }

enum DriverProfileVerificationStatus {
  approved('Approved'),
  pending('Pending'),
  additionalInformationRequired('Additional information required'),
  rejected('Rejected'),
  suspended('Suspended');

  final String label;
  const DriverProfileVerificationStatus(this.label);
}

class DriverProfileSnapshot {
  final String fullName;
  final String phone;
  final String email;
  final String driverId;
  final DriverProfileVerificationStatus verificationStatus;
  final String assignedRegion;
  final List<String> assignedBranches;
  final String? photoUrl;
  final String? photoAssetPath;
  final DateTime updatedAt;

  const DriverProfileSnapshot({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.driverId,
    required this.verificationStatus,
    required this.assignedRegion,
    required this.assignedBranches,
    required this.updatedAt,
    this.photoUrl,
    this.photoAssetPath,
  });

  bool get hasAssignedBranches => assignedBranches.isNotEmpty;
}

class DriverProfileLoadResult {
  final DriverProfileSnapshot? profile;
  final String? errorMessage;

  const DriverProfileLoadResult._({this.profile, this.errorMessage});

  const DriverProfileLoadResult.success(DriverProfileSnapshot value)
      : this._(profile: value);

  const DriverProfileLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => profile != null;
}
