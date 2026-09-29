import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../home/domain/driver_home_models.dart';
import '../../location/domain/driver_location_models.dart';
import '../domain/driver_background_location_models.dart';

enum DriverBackgroundLocationRunnerSource { device, demo }

abstract interface class DriverBackgroundLocationRunner {
  DriverBackgroundLocationRunnerSource get source;

  Stream<DriverGpsFix> watch(DriverBackgroundLocationSettings settings);
}

class DeviceDriverBackgroundLocationRunner
    implements DriverBackgroundLocationRunner {
  const DeviceDriverBackgroundLocationRunner();

  @override
  DriverBackgroundLocationRunnerSource get source =>
      DriverBackgroundLocationRunnerSource.device;

  @override
  Stream<DriverGpsFix> watch(DriverBackgroundLocationSettings settings) {
    final locationSettings = _platformSettings(settings);
    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (position) => DriverGpsFix(
        coordinates: DriverCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
        state: DriverGpsState.ready,
      ),
    );
  }

  LocationSettings _platformSettings(
    DriverBackgroundLocationSettings settings,
  ) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: settings.distanceFilterMeters,
        intervalDuration: settings.interval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Getin Driver location active',
          notificationText:
              'Location updates continue while you are online or completing a delivery.',
          enableWakeLock: false,
        ),
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: settings.distanceFilterMeters,
        pauseLocationUpdatesAutomatically: !settings.activeDelivery,
        showBackgroundLocationIndicator: true,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: settings.distanceFilterMeters,
    );
  }
}

class DemoDriverBackgroundLocationRunner
    implements DriverBackgroundLocationRunner {
  const DemoDriverBackgroundLocationRunner();

  @override
  DriverBackgroundLocationRunnerSource get source =>
      DriverBackgroundLocationRunnerSource.demo;

  @override
  Stream<DriverGpsFix> watch(DriverBackgroundLocationSettings settings) {
    final now = DateTime.now();
    return Stream<DriverGpsFix>.value(
      DriverGpsFix(
        coordinates: const DriverCoordinates(
          latitude: 31.2455,
          longitude: 29.9668,
        ),
        accuracyMeters: settings.activeDelivery ? 8 : 14,
        capturedAt: now,
        state: DriverGpsState.ready,
      ),
    );
  }
}
