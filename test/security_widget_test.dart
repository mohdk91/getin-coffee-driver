import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/security/data/driver_security_repository.dart';
import 'package:getin_driver/features/security/driver_security_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets('Task 36 renders account security requirements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverSecurityScreen(
          config: _config,
          repository: DemoDriverSecurityRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account security'), findsWidgets);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Driver PIN'), findsWidgets);
    expect(find.text('Biometric sign-in'), findsOneWidget);
    expect(find.byKey(const Key('security-biometric-card')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Active sessions & devices'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Active sessions & devices'), findsOneWidget);
    expect(find.text('Android phone'), findsOneWidget);
    expect(find.text('Web session'), findsOneWidget);
  });

  testWidgets('Task 36 can revoke a non-current demo device', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverSecurityScreen(
          config: _config,
          repository: DemoDriverSecurityRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final revoke = find.byKey(const Key('security-revoke-demo-web-session'));
    await tester.scrollUntilVisible(
      revoke,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(revoke);
    await tester.pumpAndSettle();

    expect(find.text('Sign out this device?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Web session'), findsNothing);
    expect(find.text('Android phone'), findsOneWidget);
  });

  testWidgets('Task 36 logout uses repository then exits current security flow',
      (
    tester,
  ) async {
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DriverSecurityScreen(
          config: _config,
          repository: DemoDriverSecurityRepository(),
          onLoggedOut: () => loggedOut = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logout = find.byKey(const Key('security-logout'));
    await tester.scrollUntilVisible(
      logout,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('security-confirm-logout')));
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
  });
}
