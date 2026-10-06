import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/commissions/driver_commissions_screen.dart';
import 'package:getin_driver/features/earnings/driver_earnings_screen.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );

  testWidgets('Task 27 renders backend-driven commission policy',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DriverCommissionsScreen(config: config)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Driver Commissions'), findsOneWidget);
    expect(find.text('Commission policy'), findsOneWidget);
    expect(find.textContaining('TEST DATA'), findsOneWidget);
    expect(find.text('Getin pay rules are authoritative'), findsOneWidget);
    expect(find.text('Base delivery earning'), findsOneWidget);
    expect(find.text('Distance bonus'), findsWidgets);
    expect(find.text('Peak bonus'), findsWidgets);
    expect(find.text('Customer tips'), findsOneWidget);
    expect(find.text('Adjustments'), findsWidgets);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('Task 27 earnings screen opens Driver commissions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverEarningsScreen(config: config)),
      ),
    );
    await tester.pumpAndSettle();

    final commissions = find.text('Driver commissions');
    expect(commissions, findsOneWidget);

    await tester.ensureVisible(commissions);
    await tester.tap(commissions);
    await tester.pumpAndSettle();

    expect(find.text('Commission policy'), findsOneWidget);
    expect(find.text('Getin pay rules are authoritative'), findsOneWidget);
  });
}
