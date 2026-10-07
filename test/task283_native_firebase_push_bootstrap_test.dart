import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/push/driver_push_models.dart';

void main() {
  test('Task 283 parses the authoritative order-offer push payload', () {
    final intent = DriverPushIntent.fromData(
      origin: DriverPushOrigin.foreground,
      data: const <String, dynamic>{
        'notification_id': '90',
        'type': 'order_available',
        'action_route': 'driver/orders/new',
        'order_id': '515',
        'order_number': 'GD-515',
        'offer_id': '991',
        'expires_at': '2026-10-07T12:00:45Z',
      },
      title: 'New delivery available',
      body: 'A delivery is ready for you.',
    );

    expect(intent.isOrderOffer, isTrue);
    expect(intent.notificationId, '90');
    expect(intent.orderId, 515);
    expect(intent.offerId, 991);
    expect(intent.orderNumber, 'GD-515');
    expect(intent.expiresAt, DateTime.parse('2026-10-07T12:00:45Z'));
  });

  test('Task 283 native Firebase configuration matches Driver identifiers', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final settings = File('android/settings.gradle').readAsStringSync();
    final appGradle = File('android/app/build.gradle').readAsStringSync();
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final iosProject =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final appFramework =
        File('ios/Flutter/AppFrameworkInfo.plist').readAsStringSync();

    expect(pubspec, contains('firebase_core:'));
    expect(pubspec, contains('firebase_messaging:'));
    expect(settings, contains('com.google.gms.google-services'));
    expect(appGradle, contains('id "com.google.gms.google-services"'));
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(iosInfo, contains('<string>remote-notification</string>'));
    expect(iosProject, contains('GoogleService-Info.plist in Resources'));
    expect(iosProject,
        contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements'));
    expect(iosProject, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.0'));
    expect(podfile, contains("platform :ios, '15.0'"));
    expect(appFramework, contains('<string>15.0</string>'));

    final android = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final projectInfo = android['project_info'] as Map<String, dynamic>;
    expect(projectInfo['project_id'], 'getin-coffee');

    final clients =
        (android['client'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(
      clients.any((client) {
        final info = client['client_info'] as Map<String, dynamic>;
        final androidInfo = info['android_client_info'] as Map<String, dynamic>;
        return androidInfo['package_name'] == 'com.getincoffee.driver';
      }),
      isTrue,
    );

    final iosConfig =
        File('ios/Runner/GoogleService-Info.plist').readAsStringSync();
    expect(iosConfig, contains('<string>com.getincoffee.driver</string>'));
    expect(iosConfig, contains('<string>getin-coffee</string>'));
  });
}
