import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/domain/driver_device_readiness.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';

void main() {
  test('Task 279 ready GPS qualifies the device for a shift', () {
    final readiness = DriverDeviceReadinessSnapshot.fromGps(
      _health(DriverGpsHandlingIssue.ready),
    );

    expect(readiness.readyForShift, isTrue);
    expect(readiness.status, DriverDeviceReadinessStatus.ready);
  });

  test('Task 279 background permission remains a release readiness gate', () {
    final readiness = DriverDeviceReadinessSnapshot.fromGps(
      _health(DriverGpsHandlingIssue.backgroundPermissionDenied),
    );

    expect(readiness.readyForShift, isFalse);
    expect(
      readiness.status,
      DriverDeviceReadinessStatus.backgroundPermissionRequired,
    );
    expect(readiness.message, contains('Background location'));
  });

  test('Task 279 stale and inaccurate fixes cannot be treated as ready', () {
    expect(
      DriverDeviceReadinessSnapshot.fromGps(
        _health(DriverGpsHandlingIssue.staleLocation),
      ).readyForShift,
      isFalse,
    );
    expect(
      DriverDeviceReadinessSnapshot.fromGps(
        _health(DriverGpsHandlingIssue.inaccurateGps),
      ).readyForShift,
      isFalse,
    );
  });
}

DriverGpsHealthSnapshot _health(DriverGpsHandlingIssue issue) {
  final now = DateTime(2026, 10, 6, 20);
  return DriverGpsHealthSnapshot(
    issue: issue,
    locationServicesEnabled: issue != DriverGpsHandlingIssue.locationDisabled,
    foregroundPermission: issue == DriverGpsHandlingIssue.permissionDenied
        ? DriverLocationPermissionState.denied
        : DriverLocationPermissionState.granted,
    backgroundPermission:
        issue == DriverGpsHandlingIssue.backgroundPermissionDenied
            ? DriverBackgroundPermissionState.denied
            : DriverBackgroundPermissionState.granted,
    fix: DriverGpsFix(
      coordinates: const DriverCoordinates(latitude: 31.2, longitude: 29.9),
      accuracyMeters: issue == DriverGpsHandlingIssue.inaccurateGps ? 150 : 8,
      capturedAt: issue == DriverGpsHandlingIssue.staleLocation
          ? now.subtract(const Duration(minutes: 10))
          : now,
      state: issue == DriverGpsHandlingIssue.ready
          ? DriverGpsState.ready
          : DriverGpsState.stale,
    ),
    checkedAt: now,
    message: 'test',
  );
}
