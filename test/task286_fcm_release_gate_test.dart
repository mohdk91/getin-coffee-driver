import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 286 release gate checks complete native push wiring', () {
    final gate = File('tool/release/rc_gate.sh').readAsStringSync();

    expect(gate, contains('firebase_core:'));
    expect(gate, contains('firebase_messaging:'));
    expect(gate, contains('com.google.gms.google-services'));
    expect(gate, contains('android.permission.POST_NOTIFICATIONS'));
    expect(gate, contains('remote-notification'));
    expect(gate, contains('DriverPushService.instance.initialize'));
    expect(gate, contains('onTokenRefresh.listen'));
    expect(gate, contains('onMessageOpenedApp'));
    expect(gate, contains('getInitialMessage'));
    expect(gate, contains('com.getincoffee.driver'));
  });
}
