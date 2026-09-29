enum DriverDeliveryState {
  available,
  accepted,
  goingToBranch,
  arrivedAtBranch,
  pickedUp,
  outForDelivery,
  arrivedCustomer,
  verificationPending,
  delivered,
  cancelled,
  failedDelivery,
  returnedToBranch,
}

extension DriverDeliveryStatePresentation on DriverDeliveryState {
  String get wireValue => switch (this) {
        DriverDeliveryState.available => 'available',
        DriverDeliveryState.accepted => 'accepted',
        DriverDeliveryState.goingToBranch => 'going_to_branch',
        DriverDeliveryState.arrivedAtBranch => 'arrived_at_branch',
        DriverDeliveryState.pickedUp => 'picked_up',
        DriverDeliveryState.outForDelivery => 'out_for_delivery',
        DriverDeliveryState.arrivedCustomer => 'arrived_customer',
        DriverDeliveryState.verificationPending => 'verification_pending',
        DriverDeliveryState.delivered => 'delivered',
        DriverDeliveryState.cancelled => 'cancelled',
        DriverDeliveryState.failedDelivery => 'failed_delivery',
        DriverDeliveryState.returnedToBranch => 'returned_to_branch',
      };

  String get label => switch (this) {
        DriverDeliveryState.available => 'Available',
        DriverDeliveryState.accepted => 'Accepted',
        DriverDeliveryState.goingToBranch => 'Going to branch',
        DriverDeliveryState.arrivedAtBranch => 'Arrived at branch',
        DriverDeliveryState.pickedUp => 'Picked up',
        DriverDeliveryState.outForDelivery => 'Out for delivery',
        DriverDeliveryState.arrivedCustomer => 'Arrived at customer',
        DriverDeliveryState.verificationPending => 'Verification pending',
        DriverDeliveryState.delivered => 'Delivered',
        DriverDeliveryState.cancelled => 'Cancelled',
        DriverDeliveryState.failedDelivery => 'Failed delivery',
        DriverDeliveryState.returnedToBranch => 'Returned to branch',
      };

  bool get isTerminal =>
      this == DriverDeliveryState.delivered ||
      this == DriverDeliveryState.cancelled ||
      this == DriverDeliveryState.failedDelivery ||
      this == DriverDeliveryState.returnedToBranch;

  bool get isProblemState =>
      this == DriverDeliveryState.cancelled ||
      this == DriverDeliveryState.failedDelivery ||
      this == DriverDeliveryState.returnedToBranch;

  bool get usesDeliveryDestinationFlow =>
      this == DriverDeliveryState.outForDelivery ||
      this == DriverDeliveryState.arrivedCustomer ||
      this == DriverDeliveryState.verificationPending ||
      this == DriverDeliveryState.failedDelivery ||
      this == DriverDeliveryState.returnedToBranch ||
      this == DriverDeliveryState.delivered;

  int? get coreStepIndex {
    final index = DriverDeliveryStateMachine.corePath.indexOf(this);
    return index < 0 ? null : index;
  }
}

DriverDeliveryState driverDeliveryStateFromStatus(String status) {
  final normalized =
      status.toLowerCase().replaceAll('• demo', '').replaceAll('_', ' ').trim();

  if (normalized.contains('returned to branch') ||
      normalized.contains('return to branch')) {
    return DriverDeliveryState.returnedToBranch;
  }
  if (normalized.contains('failed delivery') ||
      normalized.contains('failed_delivery')) {
    return DriverDeliveryState.failedDelivery;
  }
  if (normalized.contains('cancel')) {
    return DriverDeliveryState.cancelled;
  }
  if (normalized.contains('delivered')) {
    return DriverDeliveryState.delivered;
  }
  if (normalized.contains('verification')) {
    return DriverDeliveryState.verificationPending;
  }
  if (normalized.contains('arrived at customer') ||
      normalized.contains('arrived customer')) {
    return DriverDeliveryState.arrivedCustomer;
  }
  if (normalized.contains('out for delivery')) {
    return DriverDeliveryState.outForDelivery;
  }
  if (normalized.contains('picked')) {
    return DriverDeliveryState.pickedUp;
  }
  if (normalized.contains('arrived at branch') ||
      normalized.contains('arrived branch')) {
    return DriverDeliveryState.arrivedAtBranch;
  }
  if (normalized.contains('going to branch')) {
    return DriverDeliveryState.goingToBranch;
  }
  if (normalized.contains('available')) {
    return DriverDeliveryState.available;
  }
  return DriverDeliveryState.accepted;
}

class DriverDeliveryTimelineEvent {
  final DriverDeliveryState state;
  final DateTime occurredAt;
  final String source;
  final String? note;

  const DriverDeliveryTimelineEvent({
    required this.state,
    required this.occurredAt,
    required this.source,
    this.note,
  });
}

class DriverDeliveryTimeline {
  final String orderNumber;
  final DriverDeliveryState currentState;
  final List<DriverDeliveryTimelineEvent> history;

  const DriverDeliveryTimeline({
    required this.orderNumber,
    required this.currentState,
    required this.history,
  });

  bool hasVisited(DriverDeliveryState state) {
    return history.any((event) => event.state == state);
  }

  DriverDeliveryTimeline copyWith({
    DriverDeliveryState? currentState,
    List<DriverDeliveryTimelineEvent>? history,
  }) {
    return DriverDeliveryTimeline(
      orderNumber: orderNumber,
      currentState: currentState ?? this.currentState,
      history: history ?? this.history,
    );
  }
}

class DriverDeliveryTransitionResult {
  final DriverDeliveryTimeline timeline;
  final bool changed;
  final String? errorMessage;

  const DriverDeliveryTransitionResult._({
    required this.timeline,
    required this.changed,
    this.errorMessage,
  });

  const DriverDeliveryTransitionResult.success({
    required DriverDeliveryTimeline value,
    required bool changed,
  }) : this._(timeline: value, changed: changed);

  const DriverDeliveryTransitionResult.failure({
    required DriverDeliveryTimeline value,
    required String message,
  }) : this._(timeline: value, changed: false, errorMessage: message);

  bool get isSuccess => errorMessage == null;
}

class DriverDeliveryStateMachine {
  DriverDeliveryStateMachine._();

  static const List<DriverDeliveryState> corePath = [
    DriverDeliveryState.accepted,
    DriverDeliveryState.goingToBranch,
    DriverDeliveryState.arrivedAtBranch,
    DriverDeliveryState.pickedUp,
    DriverDeliveryState.outForDelivery,
    DriverDeliveryState.arrivedCustomer,
    DriverDeliveryState.verificationPending,
    DriverDeliveryState.delivered,
  ];

  static const Map<DriverDeliveryState, Set<DriverDeliveryState>> _allowed = {
    DriverDeliveryState.available: {
      DriverDeliveryState.accepted,
      DriverDeliveryState.cancelled,
    },
    DriverDeliveryState.accepted: {
      DriverDeliveryState.goingToBranch,
      DriverDeliveryState.cancelled,
    },
    DriverDeliveryState.goingToBranch: {
      DriverDeliveryState.arrivedAtBranch,
      DriverDeliveryState.cancelled,
      DriverDeliveryState.failedDelivery,
    },
    DriverDeliveryState.arrivedAtBranch: {
      DriverDeliveryState.pickedUp,
      DriverDeliveryState.cancelled,
      DriverDeliveryState.failedDelivery,
    },
    DriverDeliveryState.pickedUp: {
      DriverDeliveryState.outForDelivery,
      DriverDeliveryState.cancelled,
      DriverDeliveryState.failedDelivery,
      DriverDeliveryState.returnedToBranch,
    },
    DriverDeliveryState.outForDelivery: {
      DriverDeliveryState.arrivedCustomer,
      DriverDeliveryState.cancelled,
      DriverDeliveryState.failedDelivery,
      DriverDeliveryState.returnedToBranch,
    },
    DriverDeliveryState.arrivedCustomer: {
      DriverDeliveryState.verificationPending,
      DriverDeliveryState.cancelled,
      DriverDeliveryState.failedDelivery,
      DriverDeliveryState.returnedToBranch,
    },
    DriverDeliveryState.verificationPending: {
      DriverDeliveryState.delivered,
      DriverDeliveryState.cancelled,
      DriverDeliveryState.failedDelivery,
      DriverDeliveryState.returnedToBranch,
    },
    DriverDeliveryState.delivered: <DriverDeliveryState>{},
    DriverDeliveryState.cancelled: <DriverDeliveryState>{},
    DriverDeliveryState.failedDelivery: <DriverDeliveryState>{},
    DriverDeliveryState.returnedToBranch: <DriverDeliveryState>{},
  };

  static bool canTransition(
    DriverDeliveryState from,
    DriverDeliveryState to,
  ) {
    if (from == to) return true;
    return _allowed[from]?.contains(to) ?? false;
  }

  static DriverDeliveryTimeline seed({
    required String orderNumber,
    required DriverDeliveryState currentState,
    DateTime? occurredAt,
    String source = 'state_restore',
  }) {
    final timestamp = occurredAt ?? DateTime.now();
    final currentIndex = corePath.indexOf(currentState);

    final seededStates = currentIndex >= 0
        ? corePath.take(currentIndex + 1).toList(growable: false)
        : <DriverDeliveryState>[currentState];

    return DriverDeliveryTimeline(
      orderNumber: orderNumber.trim().toUpperCase(),
      currentState: currentState,
      history: List<DriverDeliveryTimelineEvent>.unmodifiable(
        seededStates.map(
          (state) => DriverDeliveryTimelineEvent(
            state: state,
            occurredAt: timestamp,
            source: source,
          ),
        ),
      ),
    );
  }

  static DriverDeliveryTransitionResult transition({
    required DriverDeliveryTimeline timeline,
    required DriverDeliveryState to,
    required String source,
    String? note,
    DateTime? occurredAt,
  }) {
    final from = timeline.currentState;
    if (from == to) {
      return DriverDeliveryTransitionResult.success(
        value: timeline,
        changed: false,
      );
    }

    if (!canTransition(from, to)) {
      return DriverDeliveryTransitionResult.failure(
        value: timeline,
        message:
            'Invalid delivery transition: ${from.wireValue} → ${to.wireValue}. The order state was not changed.',
      );
    }

    final event = DriverDeliveryTimelineEvent(
      state: to,
      occurredAt: occurredAt ?? DateTime.now(),
      source: source,
      note: note,
    );
    final updatedHistory = <DriverDeliveryTimelineEvent>[
      ...timeline.history,
      event,
    ];

    return DriverDeliveryTransitionResult.success(
      value: timeline.copyWith(
        currentState: to,
        history: List<DriverDeliveryTimelineEvent>.unmodifiable(updatedHistory),
      ),
      changed: true,
    );
  }

  static DriverDeliveryTransitionResult advanceTo({
    required DriverDeliveryTimeline timeline,
    required DriverDeliveryState target,
    required String source,
    String? note,
    DateTime? occurredAt,
  }) {
    if (timeline.currentState == target) {
      return DriverDeliveryTransitionResult.success(
        value: timeline,
        changed: false,
      );
    }

    final fromIndex = corePath.indexOf(timeline.currentState);
    final targetIndex = corePath.indexOf(target);
    if (fromIndex < 0 || targetIndex < 0 || targetIndex < fromIndex) {
      return transition(
        timeline: timeline,
        to: target,
        source: source,
        note: note,
        occurredAt: occurredAt,
      );
    }

    final requiredSteps = targetIndex - fromIndex;
    if (requiredSteps > 2) {
      return DriverDeliveryTransitionResult.failure(
        value: timeline,
        message:
            'Invalid delivery progression: ${timeline.currentState.wireValue} → ${target.wireValue} skips too many required states. The order state was not changed.',
      );
    }

    var working = timeline;
    var changed = false;
    for (var index = fromIndex + 1; index <= targetIndex; index++) {
      final result = transition(
        timeline: working,
        to: corePath[index],
        source: source,
        note: index == targetIndex ? note : 'Required intermediate state',
        occurredAt: occurredAt,
      );
      if (!result.isSuccess) return result;
      working = result.timeline;
      changed = changed || result.changed;
    }

    return DriverDeliveryTransitionResult.success(
      value: working,
      changed: changed,
    );
  }
}
