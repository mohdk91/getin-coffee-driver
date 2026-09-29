import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/verification/data/driver_verification_repository.dart';
import 'package:getin_driver/features/verification/domain/driver_verification_models.dart';
import 'package:getin_driver/features/verification/driver_verification_status_screen.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Widget _signIn(BuildContext context) =>
    const Scaffold(body: Text('Sign In Test'));

Future<void> _scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pending driver cannot enter the Driver app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverVerificationStatusScreen(
          config: config,
          initialProfile: DriverVerificationProfile(
            driverId: 'DRV-DEMO-003',
            displayName: 'Pending Driver',
            state: DriverVerificationState.pending,
            updatedAt: DateTime(2026, 9, 25),
          ),
          repository: const DemoDriverVerificationRepository(),
          signInBuilder: _signIn,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Application under review'), findsOneWidget);

    await _scrollToText(tester, 'Refresh Status');
    expect(find.text('Refresh Status'), findsOneWidget);
    expect(find.text('Enter Driver App'), findsNothing);
  });

  testWidgets('approved driver receives the Driver app entry action',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverVerificationStatusScreen(
          config: config,
          initialProfile: DriverVerificationProfile(
            driverId: 'DRV-DEMO-001',
            displayName: 'Demo Driver',
            state: DriverVerificationState.approved,
            updatedAt: DateTime(2026, 9, 25),
          ),
          repository: const DemoDriverVerificationRepository(),
          signInBuilder: _signIn,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('You are approved to drive'), findsOneWidget);

    await _scrollToText(tester, 'Enter Driver App');
    expect(find.text('Enter Driver App'), findsOneWidget);
  });

  testWidgets('additional information state lists requested items',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverVerificationStatusScreen(
          config: config,
          initialProfile: DriverVerificationProfile(
            driverId: 'DRV-DEMO-004',
            displayName: 'Review Driver',
            state: DriverVerificationState.additionalInformationRequired,
            updatedAt: DateTime(2026, 9, 25),
            requestedItems: const [
              'Upload a clearer National ID image',
              'Confirm the driving licence expiry date',
            ],
          ),
          repository: const DemoDriverVerificationRepository(),
          signInBuilder: _signIn,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Action Required'), findsOneWidget);

    await _scrollToText(tester, 'Information requested');
    expect(find.text('Information requested'), findsOneWidget);
    expect(find.text('Upload a clearer National ID image'), findsOneWidget);
    expect(find.text('Enter Driver App'), findsNothing);
  });
}
