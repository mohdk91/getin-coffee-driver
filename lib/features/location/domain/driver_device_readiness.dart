import 'driver_location_models.dart';

enum DriverDeviceReadinessStatus {
  ready,
  locationServicesOff,
  foregroundPermissionRequired,
  backgroundPermissionRequired,
  freshFixRequired,
  accuracyRequired,
  unavailable,
}

class DriverDeviceReadinessSnapshot {
  final DriverDeviceReadinessStatus status;
  final String title;
  final String message;

  const DriverDeviceReadinessSnapshot({
    required this.status,
    required this.title,
    required this.message,
  });

  bool get readyForShift => status == DriverDeviceReadinessStatus.ready;

  static DriverDeviceReadinessSnapshot fromGps(
    DriverGpsHealthSnapshot health,
  ) {
    return switch (health.issue) {
      DriverGpsHandlingIssue.ready => const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.ready,
          title: 'Ready for delivery work',
          message:
              'Location access, background tracking and GPS quality are ready for your shift.',
        ),
      DriverGpsHandlingIssue.locationDisabled =>
        const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.locationServicesOff,
          title: 'Turn on location services',
          message:
              'GPS must be enabled before you go online or continue a delivery.',
        ),
      DriverGpsHandlingIssue.permissionDenied =>
        const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.foregroundPermissionRequired,
          title: 'Allow location access',
          message:
              'GETIN needs location permission to verify pickup, delivery and route position.',
        ),
      DriverGpsHandlingIssue.backgroundPermissionDenied =>
        const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.backgroundPermissionRequired,
          title: 'Allow background location',
          message:
              'Background location is required so delivery tracking continues when the app is not in front.',
        ),
      DriverGpsHandlingIssue.staleLocation =>
        const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.freshFixRequired,
          title: 'Refresh your GPS position',
          message:
              'Your saved position is too old for delivery decisions. Get a fresh GPS fix before going online.',
        ),
      DriverGpsHandlingIssue.inaccurateGps =>
        const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.accuracyRequired,
          title: 'Improve GPS accuracy',
          message:
              'Move to an open area and retry until your location is accurate enough for delivery work.',
        ),
      DriverGpsHandlingIssue.unavailable => const DriverDeviceReadinessSnapshot(
          status: DriverDeviceReadinessStatus.unavailable,
          title: 'Location unavailable',
          message:
              'GETIN cannot confirm this device location yet. Check device settings and retry.',
        ),
    };
  }
}
