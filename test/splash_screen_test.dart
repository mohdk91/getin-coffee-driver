import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/storage/onboarding_preference_store.dart';
import 'package:getin_driver/features/splash/driver_splash_screen.dart';

class _FakeCompletionStore implements OnboardingCompletionStore {
  final bool completed;

  const _FakeCompletionStore(this.completed);

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {}
}

void main() {
  testWidgets('development replays onboarding even when completion is saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverSplashScreen(
          config: AppConfig(
            environment: AppEnvironment.development,
            apiBaseUrl: '',
          ),
          completionStore: _FakeCompletionStore(true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Drive with Getin'), findsOneWidget);
  });

  testWidgets('production skips completed onboarding and opens login', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverSplashScreen(
          config: AppConfig(
            environment: AppEnvironment.production,
            apiBaseUrl: '',
          ),
          completionStore: _FakeCompletionStore(true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Driver Login'), findsOneWidget);
    expect(
      find.text(
        'Sign-in service is unavailable right now. Please try again later.',
      ),
      findsOneWidget,
    );
  });
}
