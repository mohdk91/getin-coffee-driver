enum DriverSecurityDataSource { demo, api }

enum DriverBiometricReadiness {
  architectureReady,
  available,
  unavailable,
}

extension DriverBiometricReadinessLabel on DriverBiometricReadiness {
  String get label => switch (this) {
        DriverBiometricReadiness.architectureReady => 'Architecture ready',
        DriverBiometricReadiness.available => 'Available',
        DriverBiometricReadiness.unavailable => 'Unavailable',
      };
}

class DriverActiveSession {
  final String id;
  final String deviceName;
  final String platform;
  final String locationLabel;
  final DateTime lastActiveAt;
  final bool isCurrent;

  const DriverActiveSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.locationLabel,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  String get statusLabel => isCurrent ? 'Current device' : 'Active session';
}

class DriverSecuritySnapshot {
  final bool passwordProtected;
  final DateTime? passwordUpdatedAt;
  final bool pinConfigured;
  final int pinDigits;
  final DriverBiometricReadiness biometricReadiness;
  final bool biometricEnabled;
  final List<DriverActiveSession> activeSessions;
  final DateTime updatedAt;

  const DriverSecuritySnapshot({
    required this.passwordProtected,
    required this.passwordUpdatedAt,
    required this.pinConfigured,
    required this.pinDigits,
    required this.biometricReadiness,
    required this.biometricEnabled,
    required this.activeSessions,
    required this.updatedAt,
  });

  DriverSecuritySnapshot copyWith({
    bool? passwordProtected,
    DateTime? passwordUpdatedAt,
    bool? pinConfigured,
    int? pinDigits,
    DriverBiometricReadiness? biometricReadiness,
    bool? biometricEnabled,
    List<DriverActiveSession>? activeSessions,
    DateTime? updatedAt,
  }) {
    return DriverSecuritySnapshot(
      passwordProtected: passwordProtected ?? this.passwordProtected,
      passwordUpdatedAt: passwordUpdatedAt ?? this.passwordUpdatedAt,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      pinDigits: pinDigits ?? this.pinDigits,
      biometricReadiness: biometricReadiness ?? this.biometricReadiness,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      activeSessions: activeSessions ?? this.activeSessions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DriverSecurityLoadResult {
  final DriverSecuritySnapshot? snapshot;
  final String? errorMessage;

  const DriverSecurityLoadResult._({this.snapshot, this.errorMessage});

  const DriverSecurityLoadResult.success(DriverSecuritySnapshot snapshot)
      : this._(snapshot: snapshot);

  const DriverSecurityLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}

class DriverSecurityActionResult {
  final bool success;
  final String? message;

  const DriverSecurityActionResult._({
    required this.success,
    this.message,
  });

  const DriverSecurityActionResult.success([String? message])
      : this._(success: true, message: message);

  const DriverSecurityActionResult.failure(String message)
      : this._(success: false, message: message);
}
