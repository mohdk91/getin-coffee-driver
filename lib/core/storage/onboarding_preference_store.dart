import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_environment.dart';

abstract class OnboardingCompletionStore {
  Future<bool> isCompleted();
  Future<void> markCompleted();
}

class SharedPreferencesOnboardingCompletionStore
    implements OnboardingCompletionStore {
  static const String completionKey = 'driver_onboarding_completed_v1';

  const SharedPreferencesOnboardingCompletionStore();

  @override
  Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completionKey) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(completionKey, true);
  }
}

class OnboardingLaunchPolicy {
  const OnboardingLaunchPolicy._();

  static bool shouldShow({
    required AppEnvironment environment,
    required bool completed,
  }) {
    if (environment != AppEnvironment.production) {
      return true;
    }
    return !completed;
  }
}
