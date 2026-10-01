import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/commissions/data/driver_commission_repository.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_chat_repository.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_contact_repository.dart';
import 'package:getin_driver/features/earnings/data/driver_earnings_repository.dart';
import 'package:getin_driver/features/notifications/data/driver_notifications_repository.dart';
import 'package:getin_driver/features/order_history/data/driver_order_history_repository.dart';
import 'package:getin_driver/features/ratings/data/driver_ratings_repository.dart';
import 'package:getin_driver/features/security/data/driver_security_repository.dart';
import 'package:getin_driver/features/support/data/driver_support_chat_repository.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://example.test/api',
  );

  test('Task 133 configured production repositories are API-backed', () {
    expect(
      DriverNotificationsRepositoryFactory.create(config),
      isA<ApiDriverNotificationsRepository>(),
    );
    expect(
      DriverCustomerChatRepositoryFactory.create(config),
      isA<ApiDriverCustomerChatRepository>(),
    );
    expect(
      DriverSupportChatRepositoryFactory.create(config),
      isA<ApiDriverSupportChatRepository>(),
    );
    expect(
      DriverCustomerContactRepositoryFactory.create(config),
      isA<ApiDriverCustomerContactRepository>(),
    );
    expect(
      DriverOrderHistoryRepositoryFactory.create(config),
      isA<ApiDriverOrderHistoryRepository>(),
    );
    expect(
      DriverEarningsRepositoryFactory.create(config),
      isA<ApiDriverEarningsRepository>(),
    );
    expect(
      DriverCommissionRepositoryFactory.create(config),
      isA<ApiDriverCommissionRepository>(),
    );
    expect(
      DriverRatingsRepositoryFactory.create(config),
      isA<ApiDriverRatingsRepository>(),
    );
    expect(
      DriverSecurityRepositoryFactory.create(config),
      isA<ApiDriverSecurityRepository>(),
    );
  });
}
