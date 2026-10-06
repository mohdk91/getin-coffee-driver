import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/earnings/data/driver_earnings_repository.dart';
import 'package:getin_driver/features/notifications/data/driver_notifications_repository.dart';
import 'package:getin_driver/features/order_history/data/driver_order_history_repository.dart';

void main() {
  test(
      'Task 277 finance history and notifications are API-backed in production',
      () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );

    expect(
      DriverEarningsRepositoryFactory.create(config),
      isA<ApiDriverEarningsRepository>(),
    );
    expect(
      DriverOrderHistoryRepositoryFactory.create(config),
      isA<ApiDriverOrderHistoryRepository>(),
    );
    expect(
      DriverNotificationsRepositoryFactory.create(config),
      isA<ApiDriverNotificationsRepository>(),
    );
  });
}
