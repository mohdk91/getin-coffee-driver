enum DriverVerificationSource { demo, unavailable }

enum DriverVerificationState {
  pending,
  approved,
  rejected,
  additionalInformationRequired,
  suspended,
}

enum DriverVerificationFailureType { temporaryFailure, unavailable }

class DriverVerificationFailure {
  final DriverVerificationFailureType type;
  final String message;
  final bool retryable;

  const DriverVerificationFailure({
    required this.type,
    required this.message,
    this.retryable = false,
  });
}

class DriverVerificationResult<T> {
  final T? data;
  final DriverVerificationFailure? failure;

  const DriverVerificationResult.success(T value)
      : data = value,
        failure = null;

  const DriverVerificationResult.failure(DriverVerificationFailure value)
      : data = null,
        failure = value;

  bool get isSuccess => data != null && failure == null;
}

class DriverVerificationProfile {
  final String driverId;
  final String displayName;
  final DriverVerificationState state;
  final DateTime updatedAt;
  final String? applicationId;
  final String? note;
  final List<String> requestedItems;

  const DriverVerificationProfile({
    required this.driverId,
    required this.displayName,
    required this.state,
    required this.updatedAt,
    this.applicationId,
    this.note,
    this.requestedItems = const [],
  });

  bool get canReceiveJobs => state == DriverVerificationState.approved;

  DriverVerificationProfile copyWith({
    DriverVerificationState? state,
    DateTime? updatedAt,
    String? note,
    List<String>? requestedItems,
  }) {
    return DriverVerificationProfile(
      driverId: driverId,
      displayName: displayName,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      applicationId: applicationId,
      note: note ?? this.note,
      requestedItems: requestedItems ?? this.requestedItems,
    );
  }
}
