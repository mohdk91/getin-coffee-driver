import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/earnings/driver_earnings_screen.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );

  testWidgets('Task 260 Earnings V2 adds activity and driver-focused summary',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverEarningsScreen(config: config)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Today earnings'), findsOneWidget);
    expect(find.text('EGP 485.50'), findsOneWidget);
    expect(find.text('4 completed deliveries'), findsOneWidget);
    expect(find.text('Earnings activity'), findsOneWidget);
    expect(find.text('Avg. / delivery'), findsOneWidget);
    expect(find.text('Bonuses + tips'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
