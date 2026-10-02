import 'package:flutter/foundation.dart';

import 'app_environment.dart';

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration requestTimeout;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.requestTimeout = const Duration(seconds: 20),
  });

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    const timeoutSeconds = int.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: 20,
    );

    return AppConfig(
      environment: AppEnvironment.parse(environmentValue),
      apiBaseUrl: apiBaseUrl.trim(),
      requestTimeout: const Duration(
        seconds: timeoutSeconds > 0 ? timeoutSeconds : 20,
      ),
    );
  }

  bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  /// Demo repositories are available only to development/test builds.
  /// A compiled release must never silently fall back to local sample data.
  bool get allowsDemo =>
      environment == AppEnvironment.development && !kReleaseMode;

  bool get isProduction => environment == AppEnvironment.production;

  bool get requiresApi => !allowsDemo;

  String get environmentBadge => environment.key.toUpperCase();
}
