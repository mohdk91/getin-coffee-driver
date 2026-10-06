import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';
import 'package:getin_driver/features/profile/driver_profile_screen.dart';

const _profileListKey = PageStorageKey<String>('driver-profile-list');
const _testLabEntryKey = Key('profile-test-lab-entry');

Future<void> _revealTestLabEntry(WidgetTester tester) async {
  final profileList = find.byKey(_profileListKey);
  expect(profileList, findsOneWidget);

  for (var attempt = 0;
      attempt < 8 && find.byKey(_testLabEntryKey).evaluate().isEmpty;
      attempt += 1) {
    await tester.drag(profileList, const Offset(0, -260));
    await tester.pumpAndSettle();
  }

  final entry = find.byKey(_testLabEntryKey);
  expect(entry, findsOneWidget);
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Task 267 exposes Test Lab only inside enabled Profile',
      (tester) async {
    var opened = false;
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
      uatDemoRequested: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DriverProfileScreen(
          config: config,
          repository: const DemoDriverProfileRepository(),
          onOpenTestLab: () => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _revealTestLabEntry(tester);

    expect(find.text('Test Lab'), findsOneWidget);
    await tester.tap(find.byKey(_testLabEntryKey));
    expect(opened, isTrue);
  });

  testWidgets('Task 267 hides Test Lab from production profile',
      (tester) async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverProfileScreen(
          config: config,
          repository: DemoDriverProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_testLabEntryKey), findsNothing);
    expect(find.text('UAT'), findsNothing);
  });
}
