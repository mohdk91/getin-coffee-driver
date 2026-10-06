import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/auth/data/driver_auth_repository.dart';
import 'package:getin_driver/features/auth/domain/driver_auth_models.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';
import 'package:getin_driver/features/profile/domain/driver_profile_models.dart';

void main() {
  test('Task 268 local data is allowed only in unconfigured development debug',
      () {
    const local = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );
    const configuredDevelopment = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );
    const production = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );

    expect(local.allowsDemo, isTrue);
    expect(local.testLabEnabled, isTrue);
    expect(local.requiresApi, isFalse);

    expect(configuredDevelopment.allowsDemo, isFalse);
    expect(configuredDevelopment.testLabEnabled, isFalse);
    expect(configuredDevelopment.requiresApi, isTrue);

    expect(production.allowsDemo, isFalse);
    expect(production.testLabEnabled, isFalse);
    expect(production.requiresApi, isTrue);
  });

  test('Task 268 configured development selects API repositories', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );

    expect(DriverAuthRepositoryFactory.create(config).source,
        DriverAuthSource.api);
    expect(DriverHomeRepositoryFactory.create(config).source,
        DriverHomeDataSource.api);
    expect(DriverProfileRepositoryFactory.create(config).source,
        DriverProfileDataSource.api);
  });

  test('Task 268 keeps legacy UAT flag as a strict alias', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );
    expect(config.uatDemoEnabled, config.testLabEnabled);
  });
}
