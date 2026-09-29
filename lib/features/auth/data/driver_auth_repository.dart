import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_auth_models.dart';

abstract class DriverAuthRepository {
  DriverAuthSource get source;

  Future<DriverAuthResult<DriverOtpChallenge>> requestOtp({
    required String dialCode,
    required String phoneNumber,
  });

  Future<DriverAuthResult<DriverAuthenticatedAccount>> verifyOtp({
    required DriverOtpChallenge challenge,
    required String code,
  });

  Future<DriverAuthResult<DriverAuthenticatedAccount>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<DriverAuthResult<DriverPasswordResetReceipt>> requestPasswordReset({
    required String identifier,
  });
}

class DriverAuthRepositoryFactory {
  DriverAuthRepositoryFactory._();

  static DriverAuthRepository create(AppConfig config) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverAuthRepository();
    }

    return const UnavailableDriverAuthRepository();
  }
}

class DemoDriverAuthRepository implements DriverAuthRepository {
  const DemoDriverAuthRepository();

  static const _delay = Duration(milliseconds: 520);

  @override
  DriverAuthSource get source => DriverAuthSource.demo;

  @override
  Future<DriverAuthResult<DriverOtpChallenge>> requestOtp({
    required String dialCode,
    required String phoneNumber,
  }) async {
    await Future<void>.delayed(_delay);
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 7 || digits.length > 15) {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.invalidInput,
          message: 'Enter a valid mobile number.',
        ),
      );
    }

    if (digits.endsWith('0000000')) {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.temporaryFailure,
          message: 'Demo request failed. Your number was not changed. Retry.',
          retryable: true,
        ),
      );
    }

    return DriverAuthResult.success(
      DriverOtpChallenge(
        id: 'demo-$dialCode-$digits',
        destinationLabel: '$dialCode $phoneNumber',
      ),
    );
  }

  @override
  Future<DriverAuthResult<DriverAuthenticatedAccount>> verifyOtp({
    required DriverOtpChallenge challenge,
    required String code,
  }) async {
    await Future<void>.delayed(_delay);

    switch (code) {
      case '123456':
        return const DriverAuthResult.success(
          DriverAuthenticatedAccount(
            driverId: 'DRV-DEMO-001',
            displayName: 'Demo Driver',
            accessState: DriverAccessState.active,
          ),
        );
      case '111111':
        return const DriverAuthResult.failure(
          DriverAuthFailure(
            type: DriverAuthFailureType.invalidOtp,
            message: 'That verification code is not valid.',
          ),
        );
      case '222222':
        return const DriverAuthResult.failure(
          DriverAuthFailure(
            type: DriverAuthFailureType.expiredOtp,
            message: 'That verification code has expired. Request a new code.',
          ),
        );
      case '333333':
        return const DriverAuthResult.success(
          DriverAuthenticatedAccount(
            driverId: 'DRV-DEMO-003',
            displayName: 'Pending Driver',
            accessState: DriverAccessState.pendingApproval,
          ),
        );
      case '444444':
        return const DriverAuthResult.success(
          DriverAuthenticatedAccount(
            driverId: 'DRV-DEMO-004',
            displayName: 'Review Driver',
            accessState: DriverAccessState.additionalInformationRequired,
          ),
        );
      case '555555':
        return const DriverAuthResult.success(
          DriverAuthenticatedAccount(
            driverId: 'DRV-DEMO-005',
            displayName: 'Suspended Driver',
            accessState: DriverAccessState.suspended,
          ),
        );
      case '666666':
        return const DriverAuthResult.success(
          DriverAuthenticatedAccount(
            driverId: 'DRV-DEMO-006',
            displayName: 'Disabled Driver',
            accessState: DriverAccessState.disabled,
          ),
        );
      case '777777':
        return const DriverAuthResult.failure(
          DriverAuthFailure(
            type: DriverAuthFailureType.temporaryFailure,
            message: 'Demo server failure. No login was completed. Retry.',
            retryable: true,
          ),
        );
      case '888888':
        return const DriverAuthResult.success(
          DriverAuthenticatedAccount(
            driverId: 'DRV-DEMO-008',
            displayName: 'Rejected Driver',
            accessState: DriverAccessState.rejected,
          ),
        );
      case '999999':
        return const DriverAuthResult.failure(
          DriverAuthFailure(
            type: DriverAuthFailureType.tooManyAttempts,
            message: 'Too many demo verification attempts. Request a new code.',
          ),
        );
      default:
        return const DriverAuthResult.failure(
          DriverAuthFailure(
            type: DriverAuthFailureType.invalidOtp,
            message: 'Use a valid 6-digit code. Demo success code: 123456.',
          ),
        );
    }
  }

  @override
  Future<DriverAuthResult<DriverAuthenticatedAccount>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_delay);
    final normalized = email.trim().toLowerCase();

    if (normalized == 'server@getin.local') {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.temporaryFailure,
          message: 'Demo server failure. No login was completed. Retry.',
          retryable: true,
        ),
      );
    }

    if (password != 'Driver123!') {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.invalidCredentials,
          message: 'Email or password is incorrect.',
        ),
      );
    }

    final account = switch (normalized) {
      'driver@getin.local' => const DriverAuthenticatedAccount(
          driverId: 'DRV-DEMO-001',
          displayName: 'Demo Driver',
          accessState: DriverAccessState.active,
        ),
      'pending@getin.local' => const DriverAuthenticatedAccount(
          driverId: 'DRV-DEMO-003',
          displayName: 'Pending Driver',
          accessState: DriverAccessState.pendingApproval,
        ),
      'review@getin.local' => const DriverAuthenticatedAccount(
          driverId: 'DRV-DEMO-004',
          displayName: 'Review Driver',
          accessState: DriverAccessState.additionalInformationRequired,
        ),
      'suspended@getin.local' => const DriverAuthenticatedAccount(
          driverId: 'DRV-DEMO-005',
          displayName: 'Suspended Driver',
          accessState: DriverAccessState.suspended,
        ),
      'disabled@getin.local' => const DriverAuthenticatedAccount(
          driverId: 'DRV-DEMO-006',
          displayName: 'Disabled Driver',
          accessState: DriverAccessState.disabled,
        ),
      'rejected@getin.local' => const DriverAuthenticatedAccount(
          driverId: 'DRV-DEMO-008',
          displayName: 'Rejected Driver',
          accessState: DriverAccessState.rejected,
        ),
      _ => null,
    };

    if (account == null) {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.invalidCredentials,
          message: 'Email or password is incorrect.',
        ),
      );
    }

    return DriverAuthResult.success(account);
  }

  @override
  Future<DriverAuthResult<DriverPasswordResetReceipt>> requestPasswordReset({
    required String identifier,
  }) async {
    await Future<void>.delayed(_delay);
    final value = identifier.trim();

    if (value.isEmpty) {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.invalidInput,
          message: 'Enter your registered email or mobile number.',
        ),
      );
    }

    if (value.toLowerCase() == 'server@getin.local') {
      return const DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.temporaryFailure,
          message: 'Demo reset request failed. Nothing was sent. Retry.',
          retryable: true,
        ),
      );
    }

    return DriverAuthResult.success(
      DriverPasswordResetReceipt(destinationLabel: value),
    );
  }
}

class UnavailableDriverAuthRepository implements DriverAuthRepository {
  const UnavailableDriverAuthRepository();

  @override
  DriverAuthSource get source => DriverAuthSource.unavailable;

  DriverAuthResult<T> _unavailable<T>() {
    return const DriverAuthResult.failure(
      DriverAuthFailure(
        type: DriverAuthFailureType.unavailable,
        message:
            'Driver authentication is not connected to the Laravel API yet. '
            'No login action was completed.',
      ),
    );
  }

  @override
  Future<DriverAuthResult<DriverOtpChallenge>> requestOtp({
    required String dialCode,
    required String phoneNumber,
  }) async {
    return _unavailable();
  }

  @override
  Future<DriverAuthResult<DriverPasswordResetReceipt>> requestPasswordReset({
    required String identifier,
  }) async {
    return _unavailable();
  }

  @override
  Future<DriverAuthResult<DriverAuthenticatedAccount>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _unavailable();
  }

  @override
  Future<DriverAuthResult<DriverAuthenticatedAccount>> verifyOtp({
    required DriverOtpChallenge challenge,
    required String code,
  }) async {
    return _unavailable();
  }
}
