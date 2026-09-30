enum DriverAuthSource { demo, api, unavailable }

enum DriverAccessState {
  active,
  pendingApproval,
  additionalInformationRequired,
  rejected,
  suspended,
  disabled,
}

enum DriverAuthFailureType {
  invalidInput,
  invalidCredentials,
  invalidOtp,
  expiredOtp,
  tooManyAttempts,
  temporaryFailure,
  unavailable,
}

class DriverAuthFailure {
  final DriverAuthFailureType type;
  final String message;
  final bool retryable;

  const DriverAuthFailure({
    required this.type,
    required this.message,
    this.retryable = false,
  });
}

class DriverAuthResult<T> {
  final T? data;
  final DriverAuthFailure? failure;

  const DriverAuthResult.success(T value)
      : data = value,
        failure = null;

  const DriverAuthResult.failure(DriverAuthFailure value)
      : data = null,
        failure = value;

  bool get isSuccess => data != null && failure == null;
}

class DriverOtpChallenge {
  final String id;
  final String destinationLabel;
  final Duration expiresIn;

  const DriverOtpChallenge({
    required this.id,
    required this.destinationLabel,
    this.expiresIn = const Duration(minutes: 5),
  });
}

class DriverAuthenticatedAccount {
  final String driverId;
  final String displayName;
  final DriverAccessState accessState;

  const DriverAuthenticatedAccount({
    required this.driverId,
    required this.displayName,
    required this.accessState,
  });
}

class DriverPasswordResetReceipt {
  final String destinationLabel;

  const DriverPasswordResetReceipt({required this.destinationLabel});
}
