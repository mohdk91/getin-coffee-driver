import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';

void main() {
  test('environment parser falls back to development', () {
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('prod'), AppEnvironment.production);
    expect(AppEnvironment.parse('something-else'), AppEnvironment.development);
  });

  test('API client joins configured base URL and path safely', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://example.test/api/',
    );

    final endpoint = const ApiClient(config).endpoint('/driver/orders');
    expect(endpoint.toString(), 'https://example.test/api/driver/orders');
  });

  test('API client refuses to invent an endpoint when not configured', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );

    expect(
      () => const ApiClient(config).endpoint('/driver/orders'),
      throwsStateError,
    );
  });
}
