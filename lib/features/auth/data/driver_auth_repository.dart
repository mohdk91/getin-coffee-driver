import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/device/driver_device_registrar.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/driver_token_store.dart';
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

  static DriverAuthRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverAuthRepository(
        context ?? DriverApiContext.create(config),
      );
    }

    if (config.allowsDemo) {
      return const DemoDriverAuthRepository();
    }

    return const UnavailableDriverAuthRepository();
  }
}

class ApiDriverAuthRepository implements DriverAuthRepository {
  final DriverApiContext context;
  late final DriverTokenStore _tokens = DriverTokenStore(context.secureStore);
  late final DriverDeviceRegistrar _devices = DriverDeviceRegistrar(context);

  ApiDriverAuthRepository(this.context);

  @override
  DriverAuthSource get source => DriverAuthSource.api;

  @override
  Future<DriverAuthResult<DriverOtpChallenge>> requestOtp({
    required String dialCode,
    required String phoneNumber,
  }) async {
    return const DriverAuthResult.failure(
      DriverAuthFailure(
        type: DriverAuthFailureType.unavailable,
        message:
            'Phone OTP is not exposed by the Driver API yet. Use email and password to sign in.',
      ),
    );
  }

  @override
  Future<DriverAuthResult<DriverAuthenticatedAccount>> verifyOtp({
    required DriverOtpChallenge challenge,
    required String code,
  }) async {
    return const DriverAuthResult.failure(
      DriverAuthFailure(
        type: DriverAuthFailureType.unavailable,
        message: 'Phone OTP verification is not exposed by the Driver API yet.',
      ),
    );
  }

  @override
  Future<DriverAuthResult<DriverAuthenticatedAccount>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final envelope = await context.apiClient.postJson(
        '/v1/driver/login',
        body: <String, Object?>{
          'identifier': email.trim(),
          'password': password,
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final rawDriver = data['driver'];
      final token = data['token']?.toString();
      if (rawDriver is! Map || token == null || token.trim().isEmpty) {
        throw const FormatException('Driver login response is incomplete.');
      }

      await _tokens.saveAccessToken(token);
      await _devices.registerBestEffort();
      return DriverAuthResult.success(
        _mapDriver(Map<String, dynamic>.from(rawDriver)),
      );
    } on ApiException catch (error) {
      return DriverAuthResult.failure(_failureFromApi(error));
    } on FormatException catch (error) {
      return DriverAuthResult.failure(
        DriverAuthFailure(
          type: DriverAuthFailureType.temporaryFailure,
          message: error.message,
          retryable: true,
        ),
      );
    }
  }

  @override
  Future<DriverAuthResult<DriverPasswordResetReceipt>> requestPasswordReset({
    required String identifier,
  }) async {
    return const DriverAuthResult.failure(
      DriverAuthFailure(
        type: DriverAuthFailureType.unavailable,
        message:
            'Password reset is not exposed by the Driver API yet. Contact Getin operations.',
      ),
    );
  }

  DriverAuthenticatedAccount _mapDriver(Map<String, dynamic> driver) {
    final accountStatus = driver['account_status']?.toString().toLowerCase();
    final approvalStatus = driver['approval_status']?.toString().toLowerCase();
    final canOperate = driver['can_operate'] == true;

    final state = accountStatus != 'active'
        ? DriverAccessState.disabled
        : switch (approvalStatus) {
            'approved' when canOperate => DriverAccessState.active,
            'rejected' => DriverAccessState.rejected,
            'suspended' => DriverAccessState.suspended,
            'under_review' => DriverAccessState.pendingApproval,
            _ => DriverAccessState.pendingApproval,
          };

    return DriverAuthenticatedAccount(
      driverId: driver['id']?.toString() ?? '',
      displayName: driver['name']?.toString() ?? 'Driver',
      accessState: state,
    );
  }

  DriverAuthFailure _failureFromApi(ApiException error) {
    final status = error.statusCode;
    if (status == 401) {
      return DriverAuthFailure(
        type: DriverAuthFailureType.invalidCredentials,
        message: error.message,
      );
    }
    if (status == 422) {
      return DriverAuthFailure(
        type: DriverAuthFailureType.invalidInput,
        message: error.message,
      );
    }
    if (status == 429) {
      return DriverAuthFailure(
        type: DriverAuthFailureType.tooManyAttempts,
        message: error.message,
      );
    }
    return DriverAuthFailure(
      type: status != null && status >= 500
          ? DriverAuthFailureType.temporaryFailure
          : DriverAuthFailureType.unavailable,
      message: error.message,
      retryable: status == null || status >= 500,
    );
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
            'Sign-in service is unavailable right now. No login action was completed.',
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
