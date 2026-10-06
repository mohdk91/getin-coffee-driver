import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';

void main() {
  test('Task 275 PIN and QR verification are API-backed in production', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );

    expect(
      DriverDeliveryPinRepositoryFactory.create(config),
      isA<ApiDriverDeliveryPinRepository>(),
    );
    expect(
      DriverDeliveryQrRepositoryFactory.create(config),
      isA<ApiDriverDeliveryQrRepository>(),
    );
  });
}
