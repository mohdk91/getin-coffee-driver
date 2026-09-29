import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';

void main() {
  testWidgets('Task 22 completed demo order is no longer shown as active',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(
            config: AppConfig(
              environment: AppEnvironment.development,
              apiBaseUrl: '',
            ),
            completedOrderNumber: 'GD-2481',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume Delivery'), findsNothing);
    expect(find.text('GD-2481'), findsNothing);
  });
}
