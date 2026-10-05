import 'package:flutter/foundation.dart';

import 'app_environment.dart';

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration requestTimeout;
  final bool uatDemoRequested;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.requestTimeout = const Duration(seconds: 20),
    this.uatDemoRequested = false,
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
    const uatDemoRequested = bool.fromEnvironment(
      'UAT_DEMO',
      defaultValue: false,
    );

    return AppConfig(
      environment: AppEnvironment.parse(environmentValue),
      apiBaseUrl: apiBaseUrl.trim(),
      requestTimeout: const Duration(
        seconds: timeoutSeconds > 0 ? timeoutSeconds : 20,
      ),
      uatDemoRequested: uatDemoRequested,
    );
  }

  bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  Uri? get apiUri => isApiConfigured ? Uri.tryParse(apiBaseUrl) : null;

  /// Development/debug builds may use HTTP for local/LAN testing, but any
  /// staging/production/release configuration must use HTTPS.
  bool get isApiTransportAllowed {
    if (!isApiConfigured) return !requiresApi;
    final uri = apiUri;
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) return false;
    if (!requiresApi) return uri.scheme == 'http' || uri.scheme == 'https';
    return uri.scheme == 'https';
  }

  /// Demo repositories are available only to development/test builds.
  /// A compiled release must never silently fall back to local sample data.
  bool get allowsDemo =>
      environment == AppEnvironment.development && !kReleaseMode;

  bool get isProduction => environment == AppEnvironment.production;

  /// Explicit visual-UAT controls are available only in development/debug.
  /// Passing UAT_DEMO=true can never activate them in staging, production,
  /// or a compiled release build.
  bool get uatDemoEnabled => uatDemoRequested && allowsDemo && !isApiConfigured;

  bool get requiresApi => !allowsDemo;

  String get environmentBadge => environment.key.toUpperCase();
}
