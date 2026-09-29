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

    return AppConfig(
      environment: AppEnvironment.parse(environmentValue),
      apiBaseUrl: apiBaseUrl.trim(),
    );
  }

  bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  String get environmentBadge => environment.key.toUpperCase();
}
