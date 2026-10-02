import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';

void main() {
  test('development can use local HTTP while staging/production require HTTPS', () {
    const dev = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://192.168.1.10:8000/api',
    );
    const stagingHttp = AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'http://staging.example.test/api',
    );
    const stagingHttps = AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://staging.example.test/api',
    );
    const productionHttps = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://api.example.test/api',
    );

    expect(dev.isApiTransportAllowed, isTrue);
    expect(stagingHttp.isApiTransportAllowed, isFalse);
    expect(stagingHttps.isApiTransportAllowed, isTrue);
    expect(productionHttps.isApiTransportAllowed, isTrue);
    expect(
      () => const ApiClient(stagingHttp).endpoint('/driver/home'),
      throwsStateError,
    );
  });

  test('Driver release boundary requires API outside allowed demo mode', () {
    final source = File('lib/core/config/app_config.dart').readAsStringSync();
    expect(source, contains('bool get requiresApi => !allowsDemo;'));
    expect(source, contains("return uri.scheme == 'https';"));
  });

  test('Android production manifest blocks backups and cleartext traffic', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
