enum DriverAssignmentDataSource { demo, api }

enum DriverAssignmentControl {
  managedByGetin('Managed by Getin'),
  backendPolicyAllowsChanges('Backend policy allows changes');

  final String label;
  const DriverAssignmentControl(this.label);
}

class DriverAssignedBranch {
  final String id;
  final String name;
  final String? area;

  const DriverAssignedBranch({
    required this.id,
    required this.name,
    this.area,
  });
}

class DriverAssignmentSnapshot {
  final String assignedCity;
  final List<String> regions;
  final List<DriverAssignedBranch> allowedBranches;
  final double serviceRadiusKm;
  final DriverAssignmentControl control;
  final String policyMessage;
  final DateTime updatedAt;

  const DriverAssignmentSnapshot({
    required this.assignedCity,
    required this.regions,
    required this.allowedBranches,
    required this.serviceRadiusKm,
    required this.control,
    required this.policyMessage,
    required this.updatedAt,
  });

  bool get hasRegions => regions.isNotEmpty;
  bool get hasAllowedBranches => allowedBranches.isNotEmpty;
  bool get driverCanChangeAssignment =>
      control == DriverAssignmentControl.backendPolicyAllowsChanges;

  String get serviceRadiusLabel {
    final wholeNumber = serviceRadiusKm == serviceRadiusKm.roundToDouble();
    final value = wholeNumber
        ? serviceRadiusKm.toStringAsFixed(0)
        : serviceRadiusKm.toStringAsFixed(1);
    return '$value km';
  }
}

class DriverAssignmentLoadResult {
  final DriverAssignmentSnapshot? assignment;
  final String? errorMessage;

  const DriverAssignmentLoadResult._({this.assignment, this.errorMessage});

  const DriverAssignmentLoadResult.success(DriverAssignmentSnapshot value)
      : this._(assignment: value);

  const DriverAssignmentLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => assignment != null;
}
