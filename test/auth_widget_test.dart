import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/auth/data/driver_auth_repository.dart';
import 'package:getin_driver/features/auth/driver_login_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets('driver login defaults to mobile and exposes email fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverLoginScreen(
          config: _config,
          repository: DemoDriverAuthRepository(),
        ),
      ),
    );

    expect(find.text('Driver Login'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Test sign-in is enabled for this non-production build.'),
        findsOneWidget);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets(
      'email login validates malformed credentials before repository call', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverLoginScreen(
          config: _config,
          repository: DemoDriverAuthRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'not-an-email');
    await tester.enterText(fields.at(1), 'short');

    final signInButton = find.text('Sign In');
    await tester.ensureVisible(signInButton);
    await tester.pumpAndSettle();
    await tester.tap(signInButton);
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });
}
