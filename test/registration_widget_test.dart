import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/auth/data/driver_auth_repository.dart';
import 'package:getin_driver/features/auth/driver_login_screen.dart';
import 'package:getin_driver/features/registration/data/driver_registration_repository.dart';
import 'package:getin_driver/features/registration/driver_registration_screen.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets('login exposes Apply to Drive and opens registration',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverLoginScreen(
          config: config,
          repository: DemoDriverAuthRepository(),
        ),
      ),
    );

    final apply = find.text('Apply to Drive');
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(find.text('Driver Registration'), findsOneWidget);
    expect(find.text('Step 1 of 7'), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
  });

  testWidgets('registration validates required personal details',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverRegistrationScreen(
          config: config,
          repository: DemoDriverRegistrationRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Date of birth is required'), findsOneWidget);
  });
}
