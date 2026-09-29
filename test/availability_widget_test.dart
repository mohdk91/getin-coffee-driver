import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('availability controls show all Task 7 states', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(config: config),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Shift availability');

    expect(find.text('Shift availability'), findsOneWidget);
    expect(find.text('Online'), findsWidgets);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('On Break'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
  });

  testWidgets('active delivery prevents going offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(config: config),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Shift availability');

    await tester.tap(find.text('Offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();

    expect(
      find.text(
        'You cannot go Offline while an active delivery still requires completion.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('active delivery may pause new jobs with On Break',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(config: config),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Shift availability');

    await tester.tap(find.text('On Break'));
    // Task #9 recalculates order eligibility after a successful availability
    // change (180 ms availability demo + 140 ms eligibility demo). Give the
    // complete async update time to finish before checking the snackbar.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Availability changed to On Break.'), findsOneWidget);
  });
}
