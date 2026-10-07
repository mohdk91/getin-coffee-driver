import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task 289 Driver video splash integration', () {
    test('video asset and posters are declared and present', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('video_player: 2.9.5'));
      expect(pubspec, contains('assets/images/splash/'));
      expect(pubspec, contains('assets/video/'));
      expect(File('assets/video/driver_splash.mp4').existsSync(), isTrue);
      expect(
        File('assets/images/splash/driver_splash_start.jpg').existsSync(),
        isTrue,
      );
      expect(
        File('assets/images/splash/driver_splash_end.jpg').existsSync(),
        isTrue,
      );
    });

    test('first Flutter frame is not blocked by push initialization', () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      final runAppIndex = mainSource.indexOf('runApp(');
      final pushIndex = mainSource.indexOf(
        'unawaited(DriverPushService.instance.initialize(config))',
      );
      expect(runAppIndex, greaterThanOrEqualTo(0));
      expect(pushIndex, greaterThan(runAppIndex));
      expect(
        mainSource,
        isNot(contains('await DriverPushService.instance.initialize(config)')),
      );
    });

    test('startup gate holds the video for the full splash duration', () {
      final appSource = File('lib/app.dart').readAsStringSync();
      expect(appSource, contains('loadingChild: const DriverVideoSplash()'));
      expect(
        appSource,
        contains('minimumLoadingDuration: const Duration(milliseconds: 3050)'),
      );

      final gateSource =
          File('lib/core/widgets/mobile_startup_gate.dart').readAsStringSync();
      expect(gateSource, contains('minimumLoadingDuration'));
      expect(gateSource, contains('_waitForMinimumLoadingDuration'));
    });

    test('video is muted and never loops', () {
      final source = File(
        'lib/features/splash/driver_video_splash.dart',
      ).readAsStringSync();
      expect(source, contains('controller.setLooping(false)'));
      expect(source, contains('controller.setVolume(0)'));
      expect(source, contains('driver_splash_end.jpg'));
    });

    test('post-video resolver no longer adds the old 1250ms delay', () {
      final source = File(
        'lib/features/splash/driver_splash_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('milliseconds: 1250')));
      expect(source, contains('driver_splash_end.jpg'));
    });
  });
}
