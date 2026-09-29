import '../../home/domain/driver_home_models.dart';

class DriverCoordinates {
  final double latitude;
  final double longitude;

  const DriverCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

class DriverGpsFix {
  final DriverCoordinates coordinates;
  final double accuracyMeters;
  final DateTime capturedAt;
  final DriverGpsState state;

  const DriverGpsFix({
    required this.coordinates,
    required this.accuracyMeters,
    required this.capturedAt,
    required this.state,
  });
}

enum DriverGpsHandlingIssue {
  ready,
  locationDisabled,
  permissionDenied,
  backgroundPermissionDenied,
  staleLocation,
  inaccurateGps,
  unavailable,
}

enum DriverLocationPermissionState {
  granted,
  denied,
  deniedForever,
  unknown,
}

enum DriverBackgroundPermissionState {
  granted,
  denied,
  unknown,
}

class DriverGpsHealthSnapshot {
  final DriverGpsHandlingIssue issue;
  final bool locationServicesEnabled;
  final DriverLocationPermissionState foregroundPermission;
  final DriverBackgroundPermissionState backgroundPermission;
  final DriverGpsFix? fix;
  final DateTime checkedAt;
  final String message;

  const DriverGpsHealthSnapshot({
    required this.issue,
    required this.locationServicesEnabled,
    required this.foregroundPermission,
    required this.backgroundPermission,
    required this.fix,
    required this.checkedAt,
    required this.message,
  });

  bool get isReady => issue == DriverGpsHandlingIssue.ready;

  DriverGpsState get homeState {
    return switch (issue) {
      DriverGpsHandlingIssue.ready => DriverGpsState.ready,
      DriverGpsHandlingIssue.locationDisabled => DriverGpsState.disabled,
      DriverGpsHandlingIssue.permissionDenied =>
        DriverGpsState.permissionDenied,
      DriverGpsHandlingIssue.backgroundPermissionDenied =>
        DriverGpsState.backgroundPermissionDenied,
      DriverGpsHandlingIssue.staleLocation => DriverGpsState.stale,
      DriverGpsHandlingIssue.inaccurateGps => DriverGpsState.inaccurate,
      DriverGpsHandlingIssue.unavailable => DriverGpsState.disabled,
    };
  }
}

class DriverServiceRegionProfile {
  final String country;
  final String city;
  final String region;
  final String zone;
  final List<String> allowedBranches;
  final double deliveryRadiusKm;
  final String vehicleType;
  final DriverGpsFix currentGps;

  const DriverServiceRegionProfile({
    required this.country,
    required this.city,
    required this.region,
    required this.zone,
    required this.allowedBranches,
    required this.deliveryRadiusKm,
    required this.vehicleType,
    required this.currentGps,
  });
}
