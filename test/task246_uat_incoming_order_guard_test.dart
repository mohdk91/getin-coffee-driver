import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';

void main() {
  test('Task 246 enables UAT controls only in development demo builds', () {
    const development = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );
    const developmentWithApi = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );
    const production = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );

    expect(development.uatDemoEnabled, isTrue);
    expect(developmentWithApi.uatDemoEnabled, isFalse);
    expect(production.uatDemoEnabled, isFalse);
  });

  test('Task 246 UAT dashboard starts online without an active order',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );

    final repository = DriverHomeRepositoryFactory.create(config);
    final result = await repository.loadDashboard();

    expect(result.isSuccess, isTrue);
    expect(result.snapshot?.activeDelivery, isNull);
    expect(result.snapshot?.availability.name, 'online');
  });
}
