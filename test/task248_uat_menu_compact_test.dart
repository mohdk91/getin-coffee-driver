import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';

const _uatConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
  uatDemoRequested: true,
);

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

Future<void> _openTestLab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_rounded));
  await tester.pumpAndSettle();
  await _revealTestLabEntry(tester);
  await tester.tap(find.byKey(_testLabEntryKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Task 248 Test Lab menu scrolls without compact Android overflow',
      (tester) async {
    tester.view.physicalSize = const Size(393, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: DriverFoundationShell(config: _uatConfig)),
    );
    await tester.pumpAndSettle();

    await _openTestLab(tester);

    expect(find.text('Driver Test Lab'), findsOneWidget);
    expect(find.text('Idle driver • broadcast offer'), findsOneWidget);
    expect(find.text('Active delivery • offer blocked'), findsOneWidget);
    expect(find.text('Broadcast race'), findsOneWidget);
    expect(find.text('Offer expiry'), findsOneWidget);

    final menuScroller = find.ancestor(
      of: find.text('Driver Test Lab'),
      matching: find.byType(SingleChildScrollView),
    );
    expect(menuScroller, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(menuScroller, const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(find.text('Offer expiry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
