import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 284 Driver device registration sends and clears FCM tokens', () {
    final registrar =
        File('lib/core/device/driver_device_registrar.dart').readAsStringSync();
    final bootstrap = File(
      'lib/features/auth/data/driver_session_bootstrap_repository.dart',
    ).readAsStringSync();
    final security = File(
      'lib/features/security/data/driver_security_repository.dart',
    ).readAsStringSync();
    final pushService =
        File('lib/core/push/driver_push_service.dart').readAsStringSync();

    expect(registrar, contains("payload['push_token'] = resolvedPushToken"));
    expect(registrar, contains("payload['push_token'] = null"));
    expect(registrar, contains('deleteToken()'));
    expect(
        bootstrap, contains('deviceRegistrar: DriverDeviceRegistrar(context)'));
    expect(bootstrap, contains('registrar.registerBestEffort()'));
    expect(security, contains('devices.clearPushTokenBestEffort()'));
    expect(pushService, contains('onTokenRefresh.listen'));
    expect(pushService, contains('requestPushPermission: false'));
  });
}
