import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/navigation/data/driver_navigation_preference_store.dart';
import 'package:getin_driver/features/navigation/domain/driver_navigation_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Task 16 defaults preferred navigation app to system default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = SharedPreferencesDriverNavigationPreferenceStore();

    expect(
      await store.loadPreferredApp(),
      DriverNavigationApp.systemDefault,
    );
  });

  test('Task 16 persists the selected preferred navigation app', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = SharedPreferencesDriverNavigationPreferenceStore();

    await store.savePreferredApp(DriverNavigationApp.googleMaps);

    expect(await store.loadPreferredApp(), DriverNavigationApp.googleMaps);
  });
}
