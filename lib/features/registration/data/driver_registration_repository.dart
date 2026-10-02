import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/device/driver_device_registrar.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/driver_token_store.dart';
import '../domain/driver_registration_models.dart';

abstract class DriverRegistrationRepository {
  DriverRegistrationSource get source;

  Future<DriverRegistrationResult<DriverRegistrationReceipt>> submit(
    DriverRegistrationDraft draft,
  );
}

class DriverRegistrationRepositoryFactory {
  DriverRegistrationRepositoryFactory._();

  static DriverRegistrationRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverRegistrationRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    if (config.allowsDemo) {
      return const DemoDriverRegistrationRepository();
    }
    return const UnavailableDriverRegistrationRepository();
  }
}

class ApiDriverRegistrationRepository implements DriverRegistrationRepository {
  final DriverApiContext context;
  late final DriverTokenStore _tokens = DriverTokenStore(context.secureStore);
  late final DriverDeviceRegistrar _devices = DriverDeviceRegistrar(context);

  ApiDriverRegistrationRepository(this.context);

  @override
  DriverRegistrationSource get source => DriverRegistrationSource.api;

  @override
  Future<DriverRegistrationResult<DriverRegistrationReceipt>> submit(
    DriverRegistrationDraft draft,
  ) async {
    if (draft.password.length < 8 ||
        draft.password != draft.passwordConfirmation) {
      return const DriverRegistrationResult.failure(
        DriverRegistrationFailure(
          type: DriverRegistrationFailureType.invalidInput,
          message: 'Enter a matching password with at least 8 characters.',
        ),
      );
    }

    final phoneDigits = draft.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = '${draft.dialCode}$phoneDigits';

    try {
      final envelope = await context.apiClient.postJson(
        '/v1/driver/register',
        body: <String, Object?>{
          'name': draft.fullName.trim(),
          'email': draft.email.trim(),
          'phone': phone,
          'password': draft.password,
          'password_confirmation': draft.passwordConfirmation,
          'language': 'en',
          'driver_license_number': draft.drivingLicenseNumber.trim(),
          'driver_license_expiry': draft.drivingLicenseExpiry.trim(),
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final driver = data['driver'];
      final token = data['token']?.toString();
      if (driver is! Map || token == null || token.trim().isEmpty) {
        throw const FormatException(
            'Driver registration response is incomplete.');
      }
      await _tokens.saveAccessToken(token);
      await _devices.registerBestEffort();
      final mapped = Map<String, dynamic>.from(driver);
      final submittedAt = DateTime.tryParse(
            mapped['application_submitted_at']?.toString() ?? '',
          ) ??
          DateTime.now();
      return DriverRegistrationResult.success(
        DriverRegistrationReceipt(
          applicationId: mapped['id']?.toString() ?? '',
          statusLabel: _statusLabel(mapped['approval_status']?.toString()),
          submittedAt: submittedAt,
        ),
      );
    } on ApiException catch (error) {
      return DriverRegistrationResult.failure(
        DriverRegistrationFailure(
          type: error.statusCode != null && error.statusCode! >= 500
              ? DriverRegistrationFailureType.temporaryFailure
              : DriverRegistrationFailureType.invalidInput,
          message: error.message,
          retryable: error.statusCode == null || error.statusCode! >= 500,
        ),
      );
    } on FormatException catch (error) {
      return DriverRegistrationResult.failure(
        DriverRegistrationFailure(
          type: DriverRegistrationFailureType.temporaryFailure,
          message: error.message,
          retryable: true,
        ),
      );
    }
  }

  String _statusLabel(String? status) => switch (status?.toLowerCase()) {
        'approved' => 'Approved',
        'under_review' => 'Under review',
        'rejected' => 'Rejected',
        'suspended' => 'Suspended',
        _ => 'Pending review',
      };
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
