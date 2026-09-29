import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_verification_models.dart';

abstract class DriverVerificationRepository {
  DriverVerificationSource get source;

  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
    DriverVerificationProfile current,
  );
}

class DriverVerificationRepositoryFactory {
  DriverVerificationRepositoryFactory._();

  static DriverVerificationRepository create(AppConfig config) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverVerificationRepository();
    }
    return const UnavailableDriverVerificationRepository();
  }
}

class DemoDriverVerificationRepository implements DriverVerificationRepository {
  const DemoDriverVerificationRepository();

  @override
  DriverVerificationSource get source => DriverVerificationSource.demo;

  @override
  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
    DriverVerificationProfile current,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));

    if (current.driverId == 'DRV-DEMO-ERR') {
      return const DriverVerificationResult.failure(
        DriverVerificationFailure(
          type: DriverVerificationFailureType.temporaryFailure,
          message:
              'Demo status refresh failed. Your verification state did not change.',
          retryable: true,
        ),
      );
    }

    final state = switch (current.driverId) {
      'DRV-DEMO-001' => DriverVerificationState.approved,
      'DRV-DEMO-003' => DriverVerificationState.pending,
      'DRV-DEMO-004' => DriverVerificationState.additionalInformationRequired,
      'DRV-DEMO-005' => DriverVerificationState.suspended,
      'DRV-DEMO-008' => DriverVerificationState.rejected,
      _ => current.state,
    };

    final requestedItems =
        state == DriverVerificationState.additionalInformationRequired
            ? const [
                'Upload a clearer National ID image',
                'Confirm the driving licence expiry date',
              ]
            : const <String>[];

    return DriverVerificationResult.success(
      current.copyWith(
        state: state,
        updatedAt: DateTime.now(),
        requestedItems: requestedItems,
      ),
    );
  }
}

class UnavailableDriverVerificationRepository
    implements DriverVerificationRepository {
  const UnavailableDriverVerificationRepository();

  @override
  DriverVerificationSource get source => DriverVerificationSource.unavailable;

  @override
  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
    DriverVerificationProfile current,
  ) async {
    return const DriverVerificationResult.failure(
      DriverVerificationFailure(
        type: DriverVerificationFailureType.unavailable,
        message:
            'Verification status is not connected to the Laravel API yet. No status was changed.',
      ),
    );
  }
}
