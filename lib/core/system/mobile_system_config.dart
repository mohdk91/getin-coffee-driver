class MobileSystemConfig {
  final String apiVersion;
  final MobileReleaseConfig ios;
  final MobileReleaseConfig android;
  final bool forceUpdateEnabled;
  final MobileMaintenanceConfig maintenance;
  final MobileClientCompatibility client;
  final String defaultLanguage;
  final List<String> supportedLanguages;

  const MobileSystemConfig({
    required this.apiVersion,
    required this.ios,
    required this.android,
    required this.forceUpdateEnabled,
    required this.maintenance,
    required this.client,
    required this.defaultLanguage,
    required this.supportedLanguages,
  });

  factory MobileSystemConfig.fromApiEnvelope(Map<String, dynamic> envelope) {
    final data = _map(envelope['data']);
    final mobileApps = _map(data['mobile_apps']);
    final maintenance = _map(mobileApps['maintenance']);
    final languages = _map(data['languages']);
    final supported = languages['supported'];

    return MobileSystemConfig(
      apiVersion: data['api_version']?.toString() ?? 'v1',
      ios: MobileReleaseConfig.fromJson(_map(mobileApps['ios'])),
      android: MobileReleaseConfig.fromJson(_map(mobileApps['android'])),
      forceUpdateEnabled: _bool(mobileApps['force_update_enabled']),
      maintenance: MobileMaintenanceConfig(
        enabled: _bool(maintenance['enabled']),
        message: maintenance['message']?.toString(),
      ),
      client: MobileClientCompatibility.fromJson(_map(data['client'])),
      defaultLanguage: languages['default']?.toString() ?? 'en',
      supportedLanguages: supported is List
          ? supported.map((value) => value.toString()).toList(growable: false)
          : const <String>['en'],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'api_version': apiVersion,
        'mobile_apps': <String, dynamic>{
          'ios': ios.toJson(),
          'android': android.toJson(),
          'force_update_enabled': forceUpdateEnabled,
          'maintenance': maintenance.toJson(),
        },
        'client': client.toJson(),
        'languages': <String, dynamic>{
          'default': defaultLanguage,
          'supported': supportedLanguages,
        },
      };
}

class MobileReleaseConfig {
  final String minimumVersion;
  final String latestVersion;

  const MobileReleaseConfig({
    required this.minimumVersion,
    required this.latestVersion,
  });

  factory MobileReleaseConfig.fromJson(Map<String, dynamic> json) {
    return MobileReleaseConfig(
      minimumVersion: json['minimum_version']?.toString() ?? '1.0.0',
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'minimum_version': minimumVersion,
        'latest_version': latestVersion,
      };
}

class MobileMaintenanceConfig {
  final bool enabled;
  final String? message;

  const MobileMaintenanceConfig({
    required this.enabled,
    this.message,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'message': message,
      };
}

class MobileClientCompatibility {
  final String? platform;
  final String? version;
  final bool? versionValid;
  final String? minimumVersion;
  final String? latestVersion;
  final bool? updateAvailable;
  final bool? updateRequired;

  const MobileClientCompatibility({
    this.platform,
    this.version,
    this.versionValid,
    this.minimumVersion,
    this.latestVersion,
    this.updateAvailable,
    this.updateRequired,
  });

  factory MobileClientCompatibility.fromJson(Map<String, dynamic> json) {
    return MobileClientCompatibility(
      platform: json['platform']?.toString(),
      version: json['version']?.toString(),
      versionValid: _nullableBool(json['version_valid']),
      minimumVersion: json['minimum_version']?.toString(),
      latestVersion: json['latest_version']?.toString(),
      updateAvailable: _nullableBool(json['update_available']),
      updateRequired: _nullableBool(json['update_required']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'platform': platform,
        'version': version,
        'version_valid': versionValid,
        'minimum_version': minimumVersion,
        'latest_version': latestVersion,
        'update_available': updateAvailable,
        'update_required': updateRequired,
      };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

bool? _nullableBool(Object? value) {
  if (value == null) return null;
  return _bool(value);
}
