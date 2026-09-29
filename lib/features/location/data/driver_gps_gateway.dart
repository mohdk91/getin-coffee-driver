import 'package:geolocator/geolocator.dart';

import '../../home/domain/driver_home_models.dart';
import '../domain/driver_location_models.dart';

enum DriverGpsGatewaySource { device, demo, unavailable }

abstract interface class DriverGpsGateway {
  DriverGpsGatewaySource get source;

  Future<DriverGpsHealthSnapshot> check({bool requestPermission = false});

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

class DeviceDriverGpsGateway implements DriverGpsGateway {
  final Duration maxFixAge;
  final double maxAccuracyMeters;

  const DeviceDriverGpsGateway({
    this.maxFixAge = const Duration(minutes: 3),
    this.maxAccuracyMeters = 50,
  });

  @override
  DriverGpsGatewaySource get source => DriverGpsGatewaySource.device;

  @override
  Future<DriverGpsHealthSnapshot> check(
      {bool requestPermission = false}) async {
    final checkedAt = DateTime.now();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return DriverGpsHealthSnapshot(
          issue: DriverGpsHandlingIssue.locationDisabled,
          locationServicesEnabled: false,
          foregroundPermission: DriverLocationPermissionState.unknown,
          backgroundPermission: DriverBackgroundPermissionState.unknown,
          fix: null,
          checkedAt: checkedAt,
          message:
              'Location services are turned off. Enable GPS, then retry before accepting or continuing delivery work.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (requestPermission && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final foregroundState = _foregroundState(permission);
      final backgroundState = _backgroundState(permission);

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        final forever = permission == LocationPermission.deniedForever;
        return DriverGpsHealthSnapshot(
          issue: DriverGpsHandlingIssue.permissionDenied,
          locationServicesEnabled: true,
          foregroundPermission: foregroundState,
          backgroundPermission: backgroundState,
          fix: null,
          checkedAt: checkedAt,
          message: forever
              ? 'Location permission is blocked in system settings. Open app settings, allow location access, then retry.'
              : 'Location permission is required to verify pickup, delivery, eligibility and route position.',
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return DriverGpsHealthSnapshot(
          issue: DriverGpsHandlingIssue.unavailable,
          locationServicesEnabled: true,
          foregroundPermission: foregroundState,
          backgroundPermission: backgroundState,
          fix: null,
          checkedAt: checkedAt,
          message:
              'No GPS fix is available yet. Move to an open area and retry.',
        );
      }

      final capturedAt = position.timestamp;
      final ageDelta = checkedAt.difference(capturedAt);
      final age = Duration(milliseconds: ageDelta.inMilliseconds.abs());
      final isStale = age > maxFixAge;
      final isInaccurate = position.accuracy > maxAccuracyMeters;

      late final DriverGpsHandlingIssue issue;
      late final DriverGpsState fixState;
      late final String message;

      if (isStale) {
        issue = DriverGpsHandlingIssue.staleLocation;
        fixState = DriverGpsState.stale;
        message =
            'The last GPS fix is too old for delivery decisions. Retry to obtain a fresh location.';
      } else if (isInaccurate) {
        issue = DriverGpsHandlingIssue.inaccurateGps;
        fixState = DriverGpsState.inaccurate;
        message =
            'GPS accuracy is outside the allowed threshold. Move to an open area and retry.';
      } else if (backgroundState == DriverBackgroundPermissionState.denied) {
        issue = DriverGpsHandlingIssue.backgroundPermissionDenied;
        fixState = DriverGpsState.backgroundPermissionDenied;
        message =
            'Foreground GPS works, but background location is not allowed. Enable background access so delivery tracking can continue when the app is not in front.';
      } else {
        issue = DriverGpsHandlingIssue.ready;
        fixState = DriverGpsState.ready;
        message = 'GPS is current, accurate and ready for delivery work.';
      }

      return DriverGpsHealthSnapshot(
        issue: issue,
        locationServicesEnabled: true,
        foregroundPermission: foregroundState,
        backgroundPermission: backgroundState,
        fix: DriverGpsFix(
          coordinates: DriverCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          accuracyMeters: position.accuracy,
          capturedAt: capturedAt,
          state: fixState,
        ),
        checkedAt: checkedAt,
        message: message,
      );
    } catch (_) {
      return DriverGpsHealthSnapshot(
        issue: DriverGpsHandlingIssue.unavailable,
        locationServicesEnabled: false,
        foregroundPermission: DriverLocationPermissionState.unknown,
        backgroundPermission: DriverBackgroundPermissionState.unknown,
        fix: null,
        checkedAt: checkedAt,
        message:
            'GPS status could not be read from this device. Retry, or check the device location settings.',
      );
    }
  }

  static DriverLocationPermissionState _foregroundState(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        DriverLocationPermissionState.granted,
      LocationPermission.denied => DriverLocationPermissionState.denied,
      LocationPermission.deniedForever =>
        DriverLocationPermissionState.deniedForever,
      LocationPermission.unableToDetermine =>
        DriverLocationPermissionState.unknown,
    };
  }

  static DriverBackgroundPermissionState _backgroundState(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.always => DriverBackgroundPermissionState.granted,
      LocationPermission.whileInUse ||
      LocationPermission.denied ||
      LocationPermission.deniedForever =>
        DriverBackgroundPermissionState.denied,
      LocationPermission.unableToDetermine =>
        DriverBackgroundPermissionState.unknown,
    };
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

class DemoDriverGpsGateway implements DriverGpsGateway {
  DriverGpsHandlingIssue _scenario;

  DemoDriverGpsGateway({
    DriverGpsHandlingIssue scenario = DriverGpsHandlingIssue.ready,
  }) : _scenario = scenario;

  DriverGpsHandlingIssue get scenario => _scenario;

  void setScenario(DriverGpsHandlingIssue value) {
    _scenario = value;
  }

  @override
  DriverGpsGatewaySource get source => DriverGpsGatewaySource.demo;

  @override
  Future<DriverGpsHealthSnapshot> check(
      {bool requestPermission = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (requestPermission &&
        _scenario == DriverGpsHandlingIssue.permissionDenied) {
      _scenario = DriverGpsHandlingIssue.ready;
    }
    final now = DateTime.now();

    return switch (_scenario) {
      DriverGpsHandlingIssue.ready => _snapshotWithFix(
          issue: DriverGpsHandlingIssue.ready,
          state: DriverGpsState.ready,
          now: now,
          accuracyMeters: 12,
          capturedAt: now,
          background: DriverBackgroundPermissionState.granted,
          message: 'GPS is current, accurate and ready for delivery work.',
        ),
      DriverGpsHandlingIssue.locationDisabled => DriverGpsHealthSnapshot(
          issue: DriverGpsHandlingIssue.locationDisabled,
          locationServicesEnabled: false,
          foregroundPermission: DriverLocationPermissionState.granted,
          backgroundPermission: DriverBackgroundPermissionState.granted,
          fix: null,
          checkedAt: now,
          message: 'Location services are turned off. Enable GPS, then retry.',
        ),
      DriverGpsHandlingIssue.permissionDenied => DriverGpsHealthSnapshot(
          issue: DriverGpsHandlingIssue.permissionDenied,
          locationServicesEnabled: true,
          foregroundPermission: DriverLocationPermissionState.denied,
          backgroundPermission: DriverBackgroundPermissionState.denied,
          fix: null,
          checkedAt: now,
          message: 'Location permission is required for delivery work.',
        ),
      DriverGpsHandlingIssue.backgroundPermissionDenied => _snapshotWithFix(
          issue: DriverGpsHandlingIssue.backgroundPermissionDenied,
          state: DriverGpsState.backgroundPermissionDenied,
          now: now,
          accuracyMeters: 14,
          capturedAt: now,
          background: DriverBackgroundPermissionState.denied,
          message:
              'Foreground GPS works, but background location is not allowed.',
        ),
      DriverGpsHandlingIssue.staleLocation => _snapshotWithFix(
          issue: DriverGpsHandlingIssue.staleLocation,
          state: DriverGpsState.stale,
          now: now,
          accuracyMeters: 15,
          capturedAt: now.subtract(const Duration(minutes: 9)),
          background: DriverBackgroundPermissionState.granted,
          message: 'The last GPS fix is too old. Retry for a fresh location.',
        ),
      DriverGpsHandlingIssue.inaccurateGps => _snapshotWithFix(
          issue: DriverGpsHandlingIssue.inaccurateGps,
          state: DriverGpsState.inaccurate,
          now: now,
          accuracyMeters: 180,
          capturedAt: now,
          background: DriverBackgroundPermissionState.granted,
          message: 'GPS accuracy is too low. Move to an open area and retry.',
        ),
      DriverGpsHandlingIssue.unavailable => DriverGpsHealthSnapshot(
          issue: DriverGpsHandlingIssue.unavailable,
          locationServicesEnabled: true,
          foregroundPermission: DriverLocationPermissionState.granted,
          backgroundPermission: DriverBackgroundPermissionState.unknown,
          fix: null,
          checkedAt: now,
          message: 'No GPS fix is available yet. Retry.',
        ),
    };
  }

  static DriverGpsHealthSnapshot _snapshotWithFix({
    required DriverGpsHandlingIssue issue,
    required DriverGpsState state,
    required DateTime now,
    required double accuracyMeters,
    required DateTime capturedAt,
    required DriverBackgroundPermissionState background,
    required String message,
  }) {
    return DriverGpsHealthSnapshot(
      issue: issue,
      locationServicesEnabled: true,
      foregroundPermission: DriverLocationPermissionState.granted,
      backgroundPermission: background,
      fix: DriverGpsFix(
        coordinates: const DriverCoordinates(
          latitude: 31.24580,
          longitude: 29.96680,
        ),
        accuracyMeters: accuracyMeters,
        capturedAt: capturedAt,
        state: state,
      ),
      checkedAt: now,
      message: message,
    );
  }

  @override
  Future<bool> openLocationSettings() async {
    if (_scenario == DriverGpsHandlingIssue.locationDisabled) {
      _scenario = DriverGpsHandlingIssue.ready;
    }
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    if (_scenario == DriverGpsHandlingIssue.permissionDenied ||
        _scenario == DriverGpsHandlingIssue.backgroundPermissionDenied) {
      _scenario = DriverGpsHandlingIssue.ready;
    }
    return true;
  }
}

class UnavailableDriverGpsGateway implements DriverGpsGateway {
  const UnavailableDriverGpsGateway();

  @override
  DriverGpsGatewaySource get source => DriverGpsGatewaySource.unavailable;

  @override
  Future<DriverGpsHealthSnapshot> check(
      {bool requestPermission = false}) async {
    return DriverGpsHealthSnapshot(
      issue: DriverGpsHandlingIssue.unavailable,
      locationServicesEnabled: false,
      foregroundPermission: DriverLocationPermissionState.unknown,
      backgroundPermission: DriverBackgroundPermissionState.unknown,
      fix: null,
      checkedAt: DateTime.now(),
      message: 'Device GPS adapter is unavailable in this environment.',
    );
  }

  @override
  Future<bool> openLocationSettings() async => false;

  @override
  Future<bool> openAppSettings() async => false;
}
