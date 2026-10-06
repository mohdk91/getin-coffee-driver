import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';

void main() {
  test('Task 239 keeps Driver demo repositories development-only', () {
    const development = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const developmentWithApi = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
    );
    const production = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: '',
    );

    expect(development.allowsDemo, isTrue);
    expect(development.requiresApi, isFalse);
    expect(developmentWithApi.allowsDemo, isFalse);
    expect(developmentWithApi.requiresApi, isTrue);
    expect(production.allowsDemo, isFalse);
    expect(production.requiresApi, isTrue);
  });

  test('Task 239 release boundary is centralized and repository-wide', () {
    final appConfig =
        File('lib/core/config/app_config.dart').readAsStringSync();
    expect(appConfig, contains("import 'package:flutter/foundation.dart';"));
    expect(
      appConfig,
      contains('environment == AppEnvironment.development &&'),
    );
    expect(appConfig, contains('!isApiConfigured;'));
    expect(appConfig, contains('bool get requiresApi => !allowsDemo;'));

    final lib = Directory('lib');
    final directDemoSelectors = <String>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('config.environment == AppEnvironment.development') ||
          source.contains(
              'widget.config.environment == AppEnvironment.development') ||
          source.contains('config.environment != AppEnvironment.development') ||
          source.contains(
              'widget.config.environment != AppEnvironment.development')) {
        directDemoSelectors.add(entity.path);
      }
    }
    expect(
      directDemoSelectors,
      isEmpty,
      reason:
          'Driver runtime selection must use AppConfig.allowsDemo so release builds cannot enter demo repositories.',
    );

    final home = File('lib/features/home/data/driver_home_repository.dart')
        .readAsStringSync();
    final auth = File('lib/features/auth/data/driver_auth_repository.dart')
        .readAsStringSync();
    final registration = File(
            'lib/features/registration/data/driver_registration_repository.dart')
        .readAsStringSync();
    final acceptance =
        File('lib/features/orders/data/driver_order_acceptance_repository.dart')
            .readAsStringSync();
    final qr = File(
      'lib/features/delivery_verification/data/driver_delivery_qr_repository.dart',
    ).readAsStringSync();
    final background = File(
      'lib/features/background_location/data/driver_background_location_controller.dart',
    ).readAsStringSync();

    expect(home, contains('if (config.allowsDemo)'));
    expect(auth, contains('if (config.allowsDemo)'));
    expect(registration, contains('if (config.allowsDemo)'));
    expect(acceptance, contains('if (config.allowsDemo)'));
    expect(qr, contains('if (config.allowsDemo)'));
    expect(
        background, contains('final useDeviceRunner = !config.allowsDemo ||'));

    final foundation =
        File('lib/features/foundation/driver_foundation_shell.dart')
            .readAsStringSync();
    expect(
      foundation,
      contains('repository: _homeRepository,'),
      reason: 'Production Home must receive the factory-selected repository.',
    );
    expect(
      foundation,
      contains('config: widget.config,'),
      reason: 'Production navigation must receive the runtime AppConfig.',
    );
  });
}
