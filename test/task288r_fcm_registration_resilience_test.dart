import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/push/driver_push_token_provider.dart';

void main() {
  test('Task 288R retries only bounded transient FCM token failures', () {
    const policy = DriverPushTokenRetryPolicy();

    expect(policy.retryDelays, hasLength(2));
    expect(policy.retryDelays.first, const Duration(milliseconds: 750));
    expect(policy.retryDelays.last, const Duration(seconds: 2));

    expect(policy.shouldRetry(Exception('SERVICE_NOT_AVAILABLE')), isTrue);
    expect(policy.shouldRetry(Exception('temporarily unavailable')), isTrue);
    expect(policy.shouldRetry(Exception('FID_ALREADY_USED')), isTrue);
    expect(policy.shouldRetry(Exception('INVALID_ARGUMENT')), isFalse);
    expect(policy.shouldRetry(Exception('PERMISSION_DENIED')), isFalse);
  });

  test('Task 288R keeps FlutterFire versions stable and pins native FCM fixes', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final gradle = File('android/app/build.gradle').readAsStringSync();

    expect(pubspec, contains('firebase_core: 4.7.0'));
    expect(pubspec, contains('firebase_messaging: 16.2.0'));
    expect(
      gradle,
      contains('com.google.firebase:firebase-messaging:25.1.3'),
    );
    expect(
      gradle,
      contains('com.google.firebase:firebase-installations:19.1.2'),
    );
  });

  test('Task 288R preserves permission, refresh, and logout token lifecycle', () {
    final provider = File(
      'lib/core/push/driver_push_token_provider.dart',
    ).readAsStringSync();
    final registrar = File(
      'lib/core/device/driver_device_registrar.dart',
    ).readAsStringSync();
    final pushService = File(
      'lib/core/push/driver_push_service.dart',
    ).readAsStringSync();

    expect(provider, contains('requestPermission('));
    expect(provider, contains('AuthorizationStatus.denied'));
    expect(provider, contains('_client.getToken()'));
    expect(provider, contains('retryPolicy.shouldRetry(error)'));
    expect(provider, contains('await _client.deleteToken()'));
    expect(registrar, contains("payload['push_token'] = resolvedPushToken"));
    expect(registrar, contains("payload['push_token'] = null"));
    expect(pushService, contains('onTokenRefresh.listen'));
    expect(pushService, contains('requestPushPermission: false'));
  });
}
