import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/storage/onboarding_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('development and staging always replay onboarding', () {
    expect(
      OnboardingLaunchPolicy.shouldShow(
        environment: AppEnvironment.development,
        completed: true,
      ),
      isTrue,
    );
    expect(
      OnboardingLaunchPolicy.shouldShow(
        environment: AppEnvironment.staging,
        completed: true,
      ),
      isTrue,
    );
  });

  test('production remembers onboarding completion', () {
    expect(
      OnboardingLaunchPolicy.shouldShow(
        environment: AppEnvironment.production,
        completed: false,
      ),
      isTrue,
    );
    expect(
      OnboardingLaunchPolicy.shouldShow(
        environment: AppEnvironment.production,
        completed: true,
      ),
      isFalse,
    );
  });

  test('shared preferences store persists completion flag', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = SharedPreferencesOnboardingCompletionStore();

    expect(await store.isCompleted(), isFalse);
    await store.markCompleted();
    expect(await store.isCompleted(), isTrue);
  });
}
