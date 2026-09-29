import '../config/app_config.dart';

class ApiClient {
  final AppConfig config;

  const ApiClient(this.config);

  Uri endpoint(String path) {
    if (!config.isApiConfigured) {
      throw StateError(
        'API_BASE_URL is not configured. Pass it with --dart-define.',
      );
    }

    final base = config.apiBaseUrl.endsWith('/')
        ? config.apiBaseUrl.substring(0, config.apiBaseUrl.length - 1)
        : config.apiBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }
}
