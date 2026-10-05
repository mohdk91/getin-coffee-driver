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

void main() {
  testWidgets('Task 248 UAT menu scrolls without compact Android overflow', (
    tester,
  ) async {
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

    await tester.tap(find.byTooltip('UAT incoming order'));
    await tester.pumpAndSettle();

    expect(find.text('Incoming order UAT'), findsOneWidget);
    expect(find.text('Idle driver • broadcast offer'), findsOneWidget);
    expect(find.text('Active delivery • offer blocked'), findsOneWidget);
    expect(find.text('Broadcast race'), findsOneWidget);
    expect(find.text('Offer expiry'), findsOneWidget);

    final menuScroller = find.ancestor(
      of: find.text('Incoming order UAT'),
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
