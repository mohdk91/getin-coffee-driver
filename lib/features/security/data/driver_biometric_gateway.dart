import '../domain/driver_security_models.dart';

/// Platform boundary for a future native biometric implementation.
///
/// Task #36 deliberately does not pretend that Face ID, Touch ID or Android
/// biometrics are enrolled. A later native integration (for example through
/// `local_auth`) can implement this contract without changing Security UI or
/// account policy code.
abstract interface class DriverBiometricGateway {
  Future<DriverBiometricReadiness> readiness();

  Future<bool> authenticate({required String reason});
}

class UnconfiguredDriverBiometricGateway implements DriverBiometricGateway {
  const UnconfiguredDriverBiometricGateway();

  @override
  Future<DriverBiometricReadiness> readiness() async {
    return DriverBiometricReadiness.architectureReady;
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    return false;
  }
}
