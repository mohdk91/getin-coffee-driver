import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_security_models.dart';
import 'driver_biometric_gateway.dart';

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

  static DriverSecurityRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? DemoDriverSecurityRepository()
        : const UnavailableDriverSecurityRepository();
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

  final List<DriverActiveSession> _sessions = <DriverActiveSession>[
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
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _biometricReadiness = await biometricGateway.readiness();
    return DriverSecurityLoadResult.success(_snapshot());
  }

  @override
  Future<DriverSecurityActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

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
    if (newPassword == currentPassword) {
      return const DriverSecurityActionResult.failure(
        'Choose a new password that is different from the current password.',
      );
    }

    _currentPassword = newPassword;
    _passwordUpdatedAt = DateTime.now();
    return const DriverSecurityActionResult.success(
      'Password updated locally for this demo session.',
    );
  }

  @override
  Future<DriverSecurityActionResult> setPin({required String pin}) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
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
  Future<DriverSecurityActionResult> revokeSession(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final index = _sessions.indexWhere((session) => session.id == sessionId);
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
    await Future<void>.delayed(const Duration(milliseconds: 150));
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
      activeSessions: List<DriverActiveSession>.unmodifiable(_sessions),
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
  Future<DriverSecurityActionResult> setPin({required String pin}) async {
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
