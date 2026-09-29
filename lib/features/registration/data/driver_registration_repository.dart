import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_registration_models.dart';

abstract class DriverRegistrationRepository {
  DriverRegistrationSource get source;

  Future<DriverRegistrationResult<DriverRegistrationReceipt>> submit(
    DriverRegistrationDraft draft,
  );
}

class DriverRegistrationRepositoryFactory {
  DriverRegistrationRepositoryFactory._();

  static DriverRegistrationRepository create(AppConfig config) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverRegistrationRepository();
    }
    return const UnavailableDriverRegistrationRepository();
  }
}

class DemoDriverRegistrationRepository implements DriverRegistrationRepository {
  const DemoDriverRegistrationRepository();

  @override
  DriverRegistrationSource get source => DriverRegistrationSource.demo;

  @override
  Future<DriverRegistrationResult<DriverRegistrationReceipt>> submit(
    DriverRegistrationDraft draft,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!draft.acceptedDeclaration || !draft.hasRequiredDocuments) {
      return const DriverRegistrationResult.failure(
        DriverRegistrationFailure(
          type: DriverRegistrationFailureType.invalidInput,
          message:
              'Complete all required registration information before submitting.',
        ),
      );
    }

    if (draft.email.trim().toLowerCase() == 'server@getin.local') {
      return const DriverRegistrationResult.failure(
        DriverRegistrationFailure(
          type: DriverRegistrationFailureType.temporaryFailure,
          message:
              'Demo submission failed. Your application was not submitted. Retry.',
          retryable: true,
        ),
      );
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    return DriverRegistrationResult.success(
      DriverRegistrationReceipt(
        applicationId: 'DRV-DEMO-${stamp.substring(stamp.length - 6)}',
        statusLabel: 'Pending review',
        submittedAt: DateTime.now(),
      ),
    );
  }
}

class UnavailableDriverRegistrationRepository
    implements DriverRegistrationRepository {
  const UnavailableDriverRegistrationRepository();

  @override
  DriverRegistrationSource get source => DriverRegistrationSource.unavailable;

  @override
  Future<DriverRegistrationResult<DriverRegistrationReceipt>> submit(
    DriverRegistrationDraft draft,
  ) async {
    return const DriverRegistrationResult.failure(
      DriverRegistrationFailure(
        type: DriverRegistrationFailureType.unavailable,
        message: 'Driver registration is not connected to the Laravel API yet. '
            'No application was submitted.',
      ),
    );
  }
}
