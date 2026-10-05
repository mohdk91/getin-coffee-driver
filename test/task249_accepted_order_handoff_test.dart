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

      await tester.tap(find.byTooltip('UAT incoming order'));
      await tester.pumpAndSettle();
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
