import 'dart:async';

import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/device/driver_device_registrar.dart';
import '../../../core/storage/driver_token_store.dart';
import '../domain/driver_auth_models.dart';

class DriverSessionBootstrapResult {
  final DriverAuthenticatedAccount? account;
  final String? errorMessage;

  const DriverSessionBootstrapResult._({this.account, this.errorMessage});

  const DriverSessionBootstrapResult.authenticated(
    DriverAuthenticatedAccount value,
  ) : this._(account: value);

  const DriverSessionBootstrapResult.noSession() : this._();

  const DriverSessionBootstrapResult.failure(String message)
      : this._(errorMessage: message);

  bool get isAuthenticated => account != null;
}

abstract interface class DriverSessionBootstrapRepository {
  Future<DriverSessionBootstrapResult> restore();
}

class ApiDriverSessionBootstrapRepository
    implements DriverSessionBootstrapRepository {
  final DriverApiContext context;
  final DriverDeviceRegistrar? deviceRegistrar;
  late final DriverTokenStore _tokens = DriverTokenStore(context.secureStore);

  ApiDriverSessionBootstrapRepository(
    this.context, {
    this.deviceRegistrar,
  });

  @override
  Future<DriverSessionBootstrapResult> restore() async {
    try {
      if (!await _tokens.hasAccessToken()) {
        return const DriverSessionBootstrapResult.noSession();
      }

      final envelope = await context.apiClient.getJson(
        '/v1/driver/profile',
        authenticated: true,
      );
      final data = DriverApiContext.dataMap(envelope);
      final registrar = deviceRegistrar;
      if (registrar != null) {
        unawaited(registrar.registerBestEffort());
      }
      return DriverSessionBootstrapResult.authenticated(_map(data));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokens.clearAccessToken();
        return const DriverSessionBootstrapResult.noSession();
      }
      return DriverSessionBootstrapResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverSessionBootstrapResult.failure(error.message);
    } catch (_) {
      return const DriverSessionBootstrapResult.failure(
        'Could not restore the previous driver session.',
      );
    }
  }

  DriverAuthenticatedAccount _map(Map<String, dynamic> driver) {
    final accountStatus = driver['account_status']?.toString().toLowerCase();
    final approvalStatus = driver['approval_status']?.toString().toLowerCase();
    final canOperate = driver['can_operate'] == true;
    final verificationNotes =
        driver['verification_notes']?.toString().trim() ?? '';

    final state = accountStatus != 'active'
        ? DriverAccessState.disabled
        : switch (approvalStatus) {
            'approved' when canOperate => DriverAccessState.active,
            'rejected' => DriverAccessState.rejected,
            'suspended' => DriverAccessState.suspended,
            'under_review' when verificationNotes.isNotEmpty =>
              DriverAccessState.additionalInformationRequired,
            'under_review' => DriverAccessState.pendingApproval,
            _ => DriverAccessState.pendingApproval,
          };

    return DriverAuthenticatedAccount(
      driverId: driver['id']?.toString() ?? '',
      displayName: driver['name']?.toString() ?? 'Driver',
      accessState: state,
    );
  }
}

class NoopDriverSessionBootstrapRepository
    implements DriverSessionBootstrapRepository {
  const NoopDriverSessionBootstrapRepository();

  @override
  Future<DriverSessionBootstrapResult> restore() async =>
      const DriverSessionBootstrapResult.noSession();
}

class DriverSessionBootstrapRepositoryFactory {
  DriverSessionBootstrapRepositoryFactory._();

  static DriverSessionBootstrapRepository create(AppConfig config) {
    if (!config.isApiConfigured) {
      return const NoopDriverSessionBootstrapRepository();
    }
    final context = DriverApiContext.create(config);
    return ApiDriverSessionBootstrapRepository(
      context,
      deviceRegistrar: DriverDeviceRegistrar(context),
    );
  }
}
