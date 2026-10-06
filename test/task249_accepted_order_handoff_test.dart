import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';
import 'package:getin_driver/features/route/driver_route_to_branch_screen.dart';

const _uatConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
  uatDemoRequested: true,
);

const _profileListKey = PageStorageKey<String>('driver-profile-list');
const _testLabEntryKey = Key('profile-test-lab-entry');

Future<void> _openTestLab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_rounded));
  await tester.pumpAndSettle();

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
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Task 249 accepted broadcast hands off directly to branch route',
    (tester) async {
      tester.view.physicalSize = const Size(393, 851);
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
      await tester.tap(find.text('Idle driver • broadcast offer'));
      await tester.pumpAndSettle();

      expect(find.text('NEW DELIVERY'), findsOneWidget);
      expect(find.text('GD-UAT-9001'), findsOneWidget);

      await tester.tap(find.text('Accept Order'));
      // Demo acceptance deliberately simulates network/lock latency (650 ms).
      // A bare pumpAndSettle can finish before a Future.delayed schedules a
      // new frame, so advance fake time past that delay before settling.
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();

      expect(find.byType(DriverRouteToBranchScreen), findsOneWidget);
      expect(find.text('Route to Branch'), findsOneWidget);
      expect(find.text('GD-UAT-9001'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
