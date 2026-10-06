import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_chat_repository.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_contact_repository.dart';
import 'package:getin_driver/features/delivery/data/driver_start_delivery_repository.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';

void main() {
  test('Task 274 customer delivery lifecycle is API-backed in production', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );

    expect(
      DriverStartDeliveryRepositoryFactory.create(config),
      isA<ApiDriverStartDeliveryRepository>(),
    );
    expect(
      DriverDeliveryDestinationRepositoryFactory.create(config),
      isA<ApiDriverDeliveryDestinationRepository>(),
    );
    expect(
      DriverCustomerContactRepositoryFactory.create(config),
      isA<ApiDriverCustomerContactRepository>(),
    );
    expect(
      DriverCustomerChatRepositoryFactory.create(config),
      isA<ApiDriverCustomerChatRepository>(),
    );
  });
}
