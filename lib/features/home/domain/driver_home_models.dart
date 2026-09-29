import '../../active_delivery/domain/driver_delivery_state_machine.dart';

enum DriverAvailabilityState { online, offline, onBreak }

extension DriverAvailabilityStatePresentation on DriverAvailabilityState {
  String get label {
    return switch (this) {
      DriverAvailabilityState.online => 'Online',
      DriverAvailabilityState.offline => 'Offline',
      DriverAvailabilityState.onBreak => 'On Break',
    };
  }
}

enum DriverGpsState {
  ready,
  disabled,
  permissionDenied,
  backgroundPermissionDenied,
  stale,
  inaccurate,
}

class DriverActiveDeliverySummary {
  final String orderNumber;
  final String status;
  final String pickupBranch;
  final String destinationArea;
  final int etaMinutes;
  final DriverDeliveryState? state;

  const DriverActiveDeliverySummary({
    required this.orderNumber,
    required this.status,
    required this.pickupBranch,
    required this.destinationArea,
    required this.etaMinutes,
    this.state,
  });

  DriverDeliveryState get resolvedState =>
      state ?? driverDeliveryStateFromStatus(status);

  DriverActiveDeliverySummary copyWith({
    String? status,
    String? pickupBranch,
    String? destinationArea,
    int? etaMinutes,
    DriverDeliveryState? state,
  }) {
    return DriverActiveDeliverySummary(
      orderNumber: orderNumber,
      status: status ?? this.status,
      pickupBranch: pickupBranch ?? this.pickupBranch,
      destinationArea: destinationArea ?? this.destinationArea,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      state: state ?? this.state,
    );
  }
}

class DriverHomeSnapshot {
  final DriverAvailabilityState availability;
  final DriverActiveDeliverySummary? activeDelivery;
  final int availableOrders;
  final int completedToday;
  final double earningsToday;
  final String currencyCode;
  final double rating;
  final int ratingCount;
  final int unreadNotifications;
  final DriverGpsState gpsState;
  final bool internetConnected;
  final DateTime updatedAt;

  const DriverHomeSnapshot({
    required this.availability,
    required this.activeDelivery,
    required this.availableOrders,
    required this.completedToday,
    required this.earningsToday,
    required this.currencyCode,
    required this.rating,
    required this.ratingCount,
    required this.unreadNotifications,
    required this.gpsState,
    required this.internetConnected,
    required this.updatedAt,
  });

  bool get isOnline => availability == DriverAvailabilityState.online;
  bool get isOnBreak => availability == DriverAvailabilityState.onBreak;
  bool get hasUnreadNotifications => unreadNotifications > 0;

  DriverHomeSnapshot copyWith({
    DriverAvailabilityState? availability,
    DriverActiveDeliverySummary? activeDelivery,
    bool clearActiveDelivery = false,
    int? availableOrders,
    int? completedToday,
    double? earningsToday,
    String? currencyCode,
    double? rating,
    int? ratingCount,
    int? unreadNotifications,
    DriverGpsState? gpsState,
    bool? internetConnected,
    DateTime? updatedAt,
  }) {
    return DriverHomeSnapshot(
      availability: availability ?? this.availability,
      activeDelivery:
          clearActiveDelivery ? null : activeDelivery ?? this.activeDelivery,
      availableOrders: availableOrders ?? this.availableOrders,
      completedToday: completedToday ?? this.completedToday,
      earningsToday: earningsToday ?? this.earningsToday,
      currencyCode: currencyCode ?? this.currencyCode,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      gpsState: gpsState ?? this.gpsState,
      internetConnected: internetConnected ?? this.internetConnected,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
