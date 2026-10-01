import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';

void main() {
  test('Task 119 configured production exceptions use API repository', () {
    final r = DriverDeliveryExceptionRepositoryFactory.create(const AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api'));
    expect(r, isA<ApiDriverDeliveryExceptionRepository>());
  });
}
