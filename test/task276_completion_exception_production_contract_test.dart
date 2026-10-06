import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_completion/data/driver_delivery_completion_repository.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';

void main() {
  test(
      'Task 276 completion and exception recovery are API-backed in production',
      () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );

    expect(
      DriverDeliveryCompletionRepositoryFactory.create(config),
      isA<ApiDriverDeliveryCompletionRepository>(),
    );
    expect(
      DriverDeliveryExceptionRepositoryFactory.create(config),
      isA<ApiDriverDeliveryExceptionRepository>(),
    );
  });
}
