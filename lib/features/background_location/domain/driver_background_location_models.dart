import '../../home/domain/driver_home_models.dart';
import '../../location/domain/driver_location_models.dart';

enum DriverBackgroundTrackingStatus {
  stopped,
  starting,
  tracking,
  blocked,
  error,
}

enum DriverBackgroundTrackingReason {
  activeDelivery,
  onlinePolicy,
  offlineNoActiveDelivery,
  driverNotOnline,
  gpsNotReady,
  policyUnavailable,
  error,
}

extension DriverBackgroundTrackingStatusPresentation
    on DriverBackgroundTrackingStatus {
  String get label => switch (this) {
        DriverBackgroundTrackingStatus.stopped => 'Stopped',
        DriverBackgroundTrackingStatus.starting => 'Starting',
        DriverBackgroundTrackingStatus.tracking => 'Tracking',
        DriverBackgroundTrackingStatus.blocked => 'Blocked',
        DriverBackgroundTrackingStatus.error => 'Error',
      };
}

class DriverBackgroundLocationPolicy {
  final String version;
  final bool trackWhenOnline;
  final bool trackDuringActiveDelivery;
  final Duration onlineInterval;
  final int onlineDistanceFilterMeters;
  final Duration activeDeliveryInterval;
  final int activeDeliveryDistanceFilterMeters;

  const DriverBackgroundLocationPolicy({
    required this.version,
    required this.trackWhenOnline,
    required this.trackDuringActiveDelivery,
    required this.onlineInterval,
    required this.onlineDistanceFilterMeters,
    required this.activeDeliveryInterval,
    required this.activeDeliveryDistanceFilterMeters,
  });
}

class DriverBackgroundLocationContext {
  final DriverAvailabilityState availability;
  final bool hasActiveDelivery;
  final bool internetConnected;
  final DriverGpsState gpsState;

  const DriverBackgroundLocationContext({
    required this.availability,
    required this.hasActiveDelivery,
    required this.internetConnected,
    required this.gpsState,
  });
}

class DriverBackgroundLocationSettings {
  final Duration interval;
  final int distanceFilterMeters;
  final bool activeDelivery;

  const DriverBackgroundLocationSettings({
    required this.interval,
    required this.distanceFilterMeters,
    required this.activeDelivery,
  });

  @override
  bool operator ==(Object other) {
    return other is DriverBackgroundLocationSettings &&
        other.interval == interval &&
        other.distanceFilterMeters == distanceFilterMeters &&
        other.activeDelivery == activeDelivery;
  }

  @override
  int get hashCode => Object.hash(
        interval,
        distanceFilterMeters,
        activeDelivery,
      );
}

class DriverBackgroundTrackingDecision {
  final bool shouldTrack;
  final bool serverSyncAllowed;
  final DriverBackgroundTrackingReason reason;
  final DriverBackgroundLocationSettings? settings;
  final String message;

  const DriverBackgroundTrackingDecision({
    required this.shouldTrack,
    required this.serverSyncAllowed,
    required this.reason,
    required this.settings,
    required this.message,
  });
}

class DriverBackgroundTrackingSnapshot {
  final DriverBackgroundTrackingStatus status;
  final DriverBackgroundTrackingReason reason;
  final String message;
  final bool serverSyncAllowed;
  final DriverBackgroundLocationPolicy? policy;
  final DriverBackgroundLocationSettings? settings;
  final DriverGpsFix? lastFix;
  final DateTime updatedAt;

  const DriverBackgroundTrackingSnapshot({
    required this.status,
    required this.reason,
    required this.message,
    required this.serverSyncAllowed,
    required this.policy,
    required this.settings,
    required this.lastFix,
    required this.updatedAt,
  });

  factory DriverBackgroundTrackingSnapshot.initial() {
    return DriverBackgroundTrackingSnapshot(
      status: DriverBackgroundTrackingStatus.stopped,
      reason: DriverBackgroundTrackingReason.policyUnavailable,
      message: 'Background location policy has not loaded yet.',
      serverSyncAllowed: false,
      policy: null,
      settings: null,
      lastFix: null,
      updatedAt: DateTime.now(),
    );
  }

  DriverBackgroundTrackingSnapshot copyWith({
    DriverBackgroundTrackingStatus? status,
    DriverBackgroundTrackingReason? reason,
    String? message,
    bool? serverSyncAllowed,
    DriverBackgroundLocationPolicy? policy,
    DriverBackgroundLocationSettings? settings,
    bool clearSettings = false,
    DriverGpsFix? lastFix,
    DateTime? updatedAt,
  }) {
    return DriverBackgroundTrackingSnapshot(
      status: status ?? this.status,
      reason: reason ?? this.reason,
      message: message ?? this.message,
      serverSyncAllowed: serverSyncAllowed ?? this.serverSyncAllowed,
      policy: policy ?? this.policy,
      settings: clearSettings ? null : settings ?? this.settings,
      lastFix: lastFix ?? this.lastFix,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DriverBackgroundLocationPolicyEvaluator {
  const DriverBackgroundLocationPolicyEvaluator._();

  static DriverBackgroundTrackingDecision evaluate({
    required DriverBackgroundLocationPolicy? policy,
    required DriverBackgroundLocationContext context,
  }) {
    if (policy == null) {
      return const DriverBackgroundTrackingDecision(
        shouldTrack: false,
        serverSyncAllowed: false,
        reason: DriverBackgroundTrackingReason.policyUnavailable,
        settings: null,
        message:
            'Background tracking is waiting for the Getin location policy.',
      );
    }

    if (context.gpsState != DriverGpsState.ready) {
      return DriverBackgroundTrackingDecision(
        shouldTrack: false,
        serverSyncAllowed: false,
        reason: DriverBackgroundTrackingReason.gpsNotReady,
        settings: null,
        message:
            'Background tracking is blocked until GPS and background location permission are ready (${_gpsLabel(context.gpsState)}).',
      );
    }

    if (context.hasActiveDelivery && policy.trackDuringActiveDelivery) {
      return DriverBackgroundTrackingDecision(
        shouldTrack: true,
        serverSyncAllowed: context.internetConnected,
        reason: DriverBackgroundTrackingReason.activeDelivery,
        settings: DriverBackgroundLocationSettings(
          interval: policy.activeDeliveryInterval,
          distanceFilterMeters: policy.activeDeliveryDistanceFilterMeters,
          activeDelivery: true,
        ),
        message: context.internetConnected
            ? 'Active delivery tracking is running with the delivery GPS profile.'
            : 'Active delivery GPS remains available locally while offline; server location sync is paused until connectivity returns.',
      );
    }

    if (!context.internetConnected) {
      return const DriverBackgroundTrackingDecision(
        shouldTrack: false,
        serverSyncAllowed: false,
        reason: DriverBackgroundTrackingReason.offlineNoActiveDelivery,
        settings: null,
        message:
            'Background GPS is stopped while offline with no active delivery to reduce battery use.',
      );
    }

    if (context.availability == DriverAvailabilityState.online &&
        policy.trackWhenOnline) {
      return DriverBackgroundTrackingDecision(
        shouldTrack: true,
        serverSyncAllowed: true,
        reason: DriverBackgroundTrackingReason.onlinePolicy,
        settings: DriverBackgroundLocationSettings(
          interval: policy.onlineInterval,
          distanceFilterMeters: policy.onlineDistanceFilterMeters,
          activeDelivery: false,
        ),
        message:
            'Background GPS is running because the driver is Online and the Getin policy requires location updates.',
      );
    }

    return const DriverBackgroundTrackingDecision(
      shouldTrack: false,
      serverSyncAllowed: false,
      reason: DriverBackgroundTrackingReason.driverNotOnline,
      settings: null,
      message:
          'Background GPS is stopped because there is no active delivery and the driver is not Online.',
    );
  }

  static String _gpsLabel(DriverGpsState state) {
    return switch (state) {
      DriverGpsState.ready => 'ready',
      DriverGpsState.disabled => 'location disabled',
      DriverGpsState.permissionDenied => 'permission denied',
      DriverGpsState.backgroundPermissionDenied =>
        'background permission denied',
      DriverGpsState.stale => 'stale location',
      DriverGpsState.inaccurate => 'inaccurate GPS',
    };
  }
}
