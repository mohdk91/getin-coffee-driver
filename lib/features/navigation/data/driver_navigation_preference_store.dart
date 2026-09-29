import 'package:shared_preferences/shared_preferences.dart';

import '../domain/driver_navigation_models.dart';

abstract interface class DriverNavigationPreferenceStore {
  Future<DriverNavigationApp> loadPreferredApp();
  Future<void> savePreferredApp(DriverNavigationApp app);
}

class SharedPreferencesDriverNavigationPreferenceStore
    implements DriverNavigationPreferenceStore {
  static const String preferenceKey = 'driver_navigation_preferred_app_v1';

  const SharedPreferencesDriverNavigationPreferenceStore();

  @override
  Future<DriverNavigationApp> loadPreferredApp() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(preferenceKey);
    return DriverNavigationApp.values.firstWhere(
      (app) => app.name == saved,
      orElse: () => DriverNavigationApp.systemDefault,
    );
  }

  @override
  Future<void> savePreferredApp(DriverNavigationApp app) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, app.name);
  }
}
