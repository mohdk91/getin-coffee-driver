import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_verification_models.dart';

abstract class DriverVerificationRepository {
  DriverVerificationSource get source;
  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
      DriverVerificationProfile current);
}

class DriverVerificationRepositoryFactory {
  DriverVerificationRepositoryFactory._();
  static DriverVerificationRepository create(AppConfig config,
      {DriverApiContext? context}) {
    if (config.isApiConfigured) {
      return ApiDriverVerificationRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverVerificationRepository();
    }
    return const UnavailableDriverVerificationRepository();
  }
}

class ApiDriverVerificationRepository implements DriverVerificationRepository {
  final DriverApiContext context;
  const ApiDriverVerificationRepository(this.context);
  @override
  DriverVerificationSource get source => DriverVerificationSource.api;
  @override
  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
      DriverVerificationProfile current) async {
    try {
      final data = DriverApiContext.dataMap(await context.apiClient
          .getJson('/v1/driver/verification', authenticated: true));
      final approval = data['approval_status']?.toString().toLowerCase();
      final requested = (data['requested_items'] is List)
          ? (data['requested_items'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false)
          : const <String>[];
      final state = switch (approval) {
        'approved' => DriverVerificationState.approved,
        'rejected' => DriverVerificationState.rejected,
        'suspended' => DriverVerificationState.suspended,
        'under_review' when requested.isNotEmpty =>
          DriverVerificationState.additionalInformationRequired,
        _ => DriverVerificationState.pending,
      };
      return DriverVerificationResult.success(DriverVerificationProfile(
        driverId: data['id']?.toString() ?? current.driverId,
        displayName: data['name']?.toString() ?? current.displayName,
        state: state,
        updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        applicationId: current.applicationId,
        note: data['verification_notes']?.toString(),
        requestedItems: requested,
      ));
    } on ApiException catch (error) {
      return DriverVerificationResult.failure(DriverVerificationFailure(
          type: DriverVerificationFailureType.temporaryFailure,
          message: error.message,
          retryable: error.statusCode == null || error.statusCode! >= 500));
    } on FormatException catch (error) {
      return DriverVerificationResult.failure(DriverVerificationFailure(
          type: DriverVerificationFailureType.temporaryFailure,
          message: error.message,
          retryable: true));
    }
  }
}

class DemoDriverVerificationRepository implements DriverVerificationRepository {
  const DemoDriverVerificationRepository();
  @override
  DriverVerificationSource get source => DriverVerificationSource.demo;
  @override
  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
      DriverVerificationProfile current) async {
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
                'Confirm the driving licence expiry date'
              ]
            : const <String>[];
    return DriverVerificationResult.success(current.copyWith(
        state: state,
        updatedAt: DateTime.now(),
        requestedItems: requestedItems));
  }
}

class UnavailableDriverVerificationRepository
    implements DriverVerificationRepository {
  const UnavailableDriverVerificationRepository();
  @override
  DriverVerificationSource get source => DriverVerificationSource.unavailable;
  @override
  Future<DriverVerificationResult<DriverVerificationProfile>> refreshStatus(
          DriverVerificationProfile current) async =>
      const DriverVerificationResult.failure(DriverVerificationFailure(
          type: DriverVerificationFailureType.unavailable,
          message:
              'Verification status is not connected to the Laravel API yet. No status was changed.'));
}
