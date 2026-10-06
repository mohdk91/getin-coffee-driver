import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 282 release scripts use the real prod environment key', () {
    final android = File('tool/release/build_android.sh').readAsStringSync();
    final ios = File('tool/release/build_ios_codemagic.sh').readAsStringSync();

    expect(android, contains('--dart-define=APP_ENV=prod'));
    expect(ios, contains('--dart-define=APP_ENV=prod'));
    expect(android, isNot(contains('--dart-define=APP_ENV=production')));
    expect(ios, isNot(contains('--dart-define=APP_ENV=production')));
  });

  test('Task 282 RC gate refuses to hide missing native push prerequisites',
      () {
    final gate = File('tool/release/rc_gate.sh').readAsStringSync();

    expect(gate, contains('firebase_messaging:'));
    expect(gate, contains('android/app/google-services.json'));
    expect(gate, contains('ios/Runner/GoogleService-Info.plist'));
    expect(gate, contains('TRANSACTIONAL_PUSH_DRIVER'));
    expect(gate, contains('FIREBASE_CREDENTIALS'));
    expect(gate, contains('android/key.properties'));
    expect(gate, contains('RC_STATUS=BLOCKED'));
    expect(gate, contains('RC_STATUS=READY'));
  });
}
