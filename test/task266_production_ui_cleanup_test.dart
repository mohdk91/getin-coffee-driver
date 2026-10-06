import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/auth/domain/driver_auth_models.dart';
import 'package:getin_driver/features/auth/widgets/driver_auth_widgets.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';

void main() {
  testWidgets('Task 266 hides runtime plumbing when API auth is active', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverAuthModeBanner(source: DriverAuthSource.api),
        ),
      ),
    );

    expect(find.textContaining('Authentication API'), findsNothing);
    expect(find.textContaining('Laravel'), findsNothing);
    expect(find.textContaining('backend'), findsNothing);
  });

  testWidgets('Task 266 keeps unavailable auth message driver-facing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverAuthModeBanner(source: DriverAuthSource.unavailable),
        ),
      ),
    );

    expect(
      find.text(
          'Sign-in service is unavailable right now. Please try again later.'),
      findsOneWidget,
    );
    expect(find.textContaining('API'), findsNothing);
    expect(find.textContaining('Laravel'), findsNothing);
  });

  testWidgets('Task 266 labels non-production sign-in as test access', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverAuthModeBanner(
            source: DriverAuthSource.demo,
            onDemoHelp: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test sign-in is enabled for this non-production build.'),
        findsOneWidget);
    expect(find.text('Test access'), findsOneWidget);
    expect(find.textContaining('demo', findRichText: true), findsNothing);
  });

  test('Task 266 neutralizes the primary local profile identity', () async {
    final result = await const DemoDriverProfileRepository().loadProfile();
    expect(result.profile?.fullName, 'Test Driver');
    expect(result.profile?.driverId, 'DRV-0001');
  });

  test('Task 266 removes technical implementation copy from key UI screens',
      () {
    const paths = <String>[
      'lib/features/auth/widgets/driver_auth_widgets.dart',
      'lib/features/eligibility/driver_order_eligibility_screen.dart',
      'lib/features/delivery/driver_start_delivery_screen.dart',
      'lib/features/notifications/driver_notifications_screen.dart',
      'lib/features/ratings/driver_ratings_reviews_screen.dart',
      'lib/features/security/driver_security_screen.dart',
      'lib/features/commissions/driver_commissions_screen.dart',
    ];

    final source =
        paths.map((path) => File(path).readAsStringSync()).join('\n');
    for (final forbidden in <String>[
      'Authentication API is not connected',
      'Development demo.',
      'DEMO NOTIFICATIONS',
      'DEMO RATINGS',
      'DEMO COMMISSION POLICY',
      'Demo only — not acknowledged by Laravel',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
