import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/driver_token_store.dart';
import '../../../core/storage/secure_store.dart';
import '../domain/driver_security_models.dart';
import 'driver_biometric_gateway.dart';
import 'driver_sessions_repository.dart';

abstract interface class DriverSecurityRepository {
  DriverSecurityDataSource get source;

  Future<DriverSecurityLoadResult> loadSecurity();

  Future<DriverSecurityActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<DriverSecurityActionResult> setPin({
    required String pin,
  });

  Future<DriverSecurityActionResult> revokeSession(String sessionId);

  Future<DriverSecurityActionResult> logout();
}

class DriverSecurityRepositoryFactory {
  DriverSecurityRepositoryFactory._();

  static DriverSecurityRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      final apiContext = context ?? DriverApiContext.create(config);
      return ApiDriverSecurityRepository(apiContext);
    }

    return config.allowsDemo
        ? DemoDriverSecurityRepository()
        : const UnavailableDriverSecurityRepository();
  }
}

class ApiDriverSecurityRepository implements DriverSecurityRepository {
  final DriverApiContext context;
  late final DriverSessionsRepository sessions =
      DriverSessionsRepository(context);
  late final DriverTokenStore tokens = DriverTokenStore(context.secureStore);

  int minPin = 4;
  int maxPin = 6;

  ApiDriverSecurityRepository(this.context);

  @override
  DriverSecurityDataSource get source => DriverSecurityDataSource.api;

  @override
  Future<DriverSecurityLoadResult> loadSecurity() async {
    try {
      final policy = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/security/policy',
          authenticated: true,
        ),
      );
      final pinPolicy = policy['app_pin'] is Map
          ? Map<String, dynamic>.from(policy['app_pin'] as Map)
          : const <String, dynamic>{};
      minPin = (pinPolicy['min_length'] as num?)?.toInt() ?? 4;
      maxPin = (pinPolicy['max_length'] as num?)?.toInt() ?? 6;

      final active = await sessions.load();
      final pin = await context.secureStore.read(SecureStoreKeys.driverPin);

      return DriverSecurityLoadResult.success(
        DriverSecuritySnapshot(
          passwordProtected: true,
          passwordUpdatedAt: null,
          pinConfigured: pin != null && pin.isNotEmpty,
          pinDigits: pin?.length ?? minPin,
          biometricReadiness: DriverBiometricReadiness.architectureReady,
          biometricEnabled: false,
          activeSessions: active,
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverSecurityLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverSecurityLoadResult.failure(error.message);
    }
  }

  @override
  Future<DriverSecurityActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await context.apiClient.putJson(
        '/v1/driver/password',
        authenticated: true,
        body: <String, Object?>{
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
      return const DriverSecurityActionResult.success('Password updated.');
    } on ApiException catch (error) {
      return DriverSecurityActionResult.failure(error.message);
    }
  }

  @override
  Future<DriverSecurityActionResult> setPin({
    required String pin,
  }) async {
    if (pin.length < minPin ||
        pin.length > maxPin ||
        !RegExp(r'^\d+$').hasMatch(pin)) {
      return DriverSecurityActionResult.failure(
        'PIN must contain $minPin to $maxPin digits.',
      );
    }

    await context.secureStore.write(SecureStoreKeys.driverPin, pin);
    return const DriverSecurityActionResult.success(
      'Driver PIN saved securely on this device.',
    );
  }

  @override
  Future<DriverSecurityActionResult> revokeSession(String sessionId) async {
    try {
      await sessions.revoke(sessionId);
      return const DriverSecurityActionResult.success('Session signed out.');
    } on ApiException catch (error) {
      return DriverSecurityActionResult.failure(error.message);
    }
  }

  @override
  Future<DriverSecurityActionResult> logout() async {
    try {
      await sessions.revokeCurrent();
      await tokens.clearAccessToken();
      return const DriverSecurityActionResult.success('Signed out.');
    } on ApiException {
      await tokens.clearAccessToken();
      return const DriverSecurityActionResult.success(
        'Signed out on this device. The server session could not be confirmed as revoked, so review Active Sessions after signing in again.',
      );
    }
  }
}

class DemoDriverSecurityRepository implements DriverSecurityRepository {
  final DriverBiometricGateway biometricGateway;

  DemoDriverSecurityRepository({
    this.biometricGateway = const UnconfiguredDriverBiometricGateway(),
  });

  DriverBiometricReadiness _biometricReadiness =
      DriverBiometricReadiness.architectureReady;
  String _currentPassword = 'Driver123!';
  final List<DriverActiveSession> _sessions = [
    DriverActiveSession(
      id: 'demo-current-device',
      deviceName: 'Android phone',
      platform: 'Getin Driver app',
      locationLabel: 'Alexandria, Egypt',
      lastActiveAt: DateTime(2026, 9, 27, 0, 18),
      isCurrent: true,
    ),
    DriverActiveSession(
      id: 'demo-web-session',
      deviceName: 'Web session',
      platform: 'Chrome on macOS',
      locationLabel: 'Alexandria, Egypt',
      lastActiveAt: DateTime(2026, 9, 26, 18, 40),
      isCurrent: false,
    ),
  ];
  DateTime? _passwordUpdatedAt = DateTime(2026, 9, 10, 9, 30);
  bool _pinConfigured = true;
  int _pinDigits = 4;

  @override
  DriverSecurityDataSource get source => DriverSecurityDataSource.demo;

  @override
  Future<DriverSecurityLoadResult> loadSecurity() async {
    _biometricReadiness = await biometricGateway.readiness();
    return DriverSecurityLoadResult.success(_snapshot());
  }

  @override
  Future<DriverSecurityActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword != _currentPassword) {
      return const DriverSecurityActionResult.failure(
        'Current password is incorrect.',
      );
    }
    if (newPassword.length < 8) {
      return const DriverSecurityActionResult.failure(
        'New password must be at least 8 characters.',
      );
    }

    _currentPassword = newPassword;
    _passwordUpdatedAt = DateTime.now();
    return const DriverSecurityActionResult.success(
      'Password updated locally for this demo session.',
    );
  }

  @override
  Future<DriverSecurityActionResult> setPin({
    required String pin,
  }) async {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      return const DriverSecurityActionResult.failure(
        'PIN must contain 4 to 6 digits.',
      );
    }

    _pinConfigured = true;
    _pinDigits = pin.length;
    return const DriverSecurityActionResult.success(
      'Driver PIN updated locally for this demo session.',
    );
  }

  @override
  Future<DriverSecurityActionResult> revokeSession(String id) async {
    final index = _sessions.indexWhere((session) => session.id == id);
    if (index < 0) {
      return const DriverSecurityActionResult.failure(
        'That session is no longer active.',
      );
    }
    if (_sessions[index].isCurrent) {
      return const DriverSecurityActionResult.failure(
        'Use Log out to end the current device session.',
      );
    }

    _sessions.removeAt(index);
    return const DriverSecurityActionResult.success('Session signed out.');
  }

  @override
  Future<DriverSecurityActionResult> logout() async {
    return const DriverSecurityActionResult.success(
      'Demo session ended on this device.',
    );
  }

  DriverSecuritySnapshot _snapshot() {
    return DriverSecuritySnapshot(
      passwordProtected: true,
      passwordUpdatedAt: _passwordUpdatedAt,
      pinConfigured: _pinConfigured,
      pinDigits: _pinDigits,
      biometricReadiness: _biometricReadiness,
      biometricEnabled: false,
      activeSessions: List.unmodifiable(_sessions),
      updatedAt: DateTime.now(),
    );
  }
}

class UnavailableDriverSecurityRepository implements DriverSecurityRepository {
  const UnavailableDriverSecurityRepository();

  @override
  DriverSecurityDataSource get source => DriverSecurityDataSource.api;

  DriverSecurityActionResult _unavailable() {
    return const DriverSecurityActionResult.failure(
      'Account security is not connected to the Laravel API yet. No security change was made.',
    );
  }

  @override
  Future<DriverSecurityLoadResult> loadSecurity() async {
    return const DriverSecurityLoadResult.failure(
      'Account security is not connected to the Laravel API yet. Getin will not invent production sessions or security settings.',
    );
  }

  @override
  Future<DriverSecurityActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _unavailable();
  }

  @override
  Future<DriverSecurityActionResult> setPin({
    required String pin,
  }) async {
    return _unavailable();
  }

  @override
  Future<DriverSecurityActionResult> revokeSession(String sessionId) async {
    return _unavailable();
  }

  @override
  Future<DriverSecurityActionResult> logout() async {
    return _unavailable();
  }
}
