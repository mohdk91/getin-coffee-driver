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
      requestTimeout: Duration(
        seconds: timeoutSeconds > 0 ? timeoutSeconds : 20,
      ),
    );
  }

  bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  bool get isProduction => environment == AppEnvironment.production;

  bool get requiresApi => environment != AppEnvironment.development;

  String get environmentBadge => environment.key.toUpperCase();
}
