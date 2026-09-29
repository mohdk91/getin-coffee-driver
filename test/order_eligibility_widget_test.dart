import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/eligibility/driver_order_eligibility_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets('eligibility screen hides new jobs when V1 capacity is full',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverOrderEligibilityScreen(
          config: _config,
          repository: DemoDriverOrderEligibilityRepository(),
          availability: DriverAvailabilityState.online,
          activeOrderCount: 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart Order Eligibility'), findsOneWidget);
    expect(find.text('0 eligible now'), findsOneWidget);
    expect(find.textContaining('6 candidate jobs evaluated'), findsOneWidget);
    expect(
        find.textContaining('V1 allows one active delivery'), findsOneWidget);
    expect(find.text('SERVER-READY FILTER'), findsOneWidget);
  });
}
