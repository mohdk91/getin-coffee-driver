import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 245 Driver production release configuration is explicit', () {
    final buildGradle = File('android/app/build.gradle').readAsStringSync();
    expect(buildGradle, contains('targetSdk = 36'));
    expect(buildGradle, isNot(contains('signingConfig = signingConfigs.debug')));
    expect(buildGradle, contains('key.properties'));

    final androidScript = File('tool/release/build_android.sh').readAsStringSync();
    expect(androidScript, contains('--dart-define=APP_ENV=production'));
    expect(androidScript, contains('GETIN_API_BASE_URL'));
    expect(androidScript, contains('flutter build appbundle --release'));

    final iosScript = File('tool/release/build_ios_codemagic.sh').readAsStringSync();
    expect(iosScript, contains('flutter build ipa --release'));
    expect(iosScript, contains('--dart-define=APP_ENV=production'));

    final docs = File('docs/production-release.md').readAsStringSync();
    expect(docs, contains('Xcode 26 or later'));
    expect(docs, contains('iOS 13 or later'));

    expect(File('ios/Podfile').existsSync(), isTrue);
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(project, isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 12.0;')));
    expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;'));

  });
}
