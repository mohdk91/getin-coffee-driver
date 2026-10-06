import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets('Task 258 Home V2 adds visual quick actions and motivation',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverHomeDashboard(config: _config)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery in progress'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('View orders'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Earnings hub'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
