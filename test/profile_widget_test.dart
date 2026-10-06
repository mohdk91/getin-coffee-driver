import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/assignment/driver_assignment_screen.dart';
import 'package:getin_driver/features/documents/driver_documents_screen.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';
import 'package:getin_driver/features/profile/domain/driver_profile_models.dart';
import 'package:getin_driver/features/profile/driver_profile_screen.dart';
import 'package:getin_driver/features/security/driver_security_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

class _FixedProfileRepository implements DriverProfileRepository {
  @override
  DriverProfileDataSource get source => DriverProfileDataSource.demo;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    return DriverProfileLoadResult.success(
      DriverProfileSnapshot(
        fullName: 'Test Driver',
        phone: '+20 111 222 3333',
        email: 'test.driver@getin.local',
        driverId: 'DRV-TEST-032',
        verificationStatus: DriverProfileVerificationStatus.approved,
        assignedRegion: 'East Alexandria',
        assignedBranches: const ['Stanley', 'San Stefano'],
        updatedAt: DateTime(2026, 9, 26),
      ),
    );
  }
}

class _FailedProfileRepository implements DriverProfileRepository {
  @override
  DriverProfileDataSource get source => DriverProfileDataSource.api;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    return const DriverProfileLoadResult.failure('Profile API unavailable.');
  }
}

void main() {
  testWidgets('Task 32 renders every required driver profile field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(
            config: _config,
            repository: _FixedProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Driver Profile'), findsOneWidget);
    expect(find.byKey(const Key('driver-profile-photo')), findsOneWidget);
    expect(find.text('Test Driver'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('+20 111 222 3333'), findsOneWidget);
    expect(find.text('test.driver@getin.local'), findsOneWidget);
    expect(find.text('DRV-TEST-032'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('East Alexandria'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('East Alexandria'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Assigned branch(es)'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned branch(es)'), findsOneWidget);
    expect(find.text('Stanley'), findsOneWidget);
    expect(find.text('San Stefano'), findsOneWidget);
  });

  testWidgets('Task 32 profile exposes unavailable API state without fake data',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(
            config: _config,
            repository: _FailedProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile unavailable'), findsOneWidget);
    expect(find.text('Profile API unavailable.'), findsOneWidget);
    expect(find.text('Demo Driver'), findsNothing);
  });
  testWidgets('Task 34 profile entry opens Driver Documents', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(
            config: _config,
            repository: _FixedProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('profile-documents-entry'));
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(DriverDocumentsScreen), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets('Task 35 profile entry opens Branch & Region Assignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(
            config: _config,
            repository: _FixedProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('profile-assignment-entry'));
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(DriverAssignmentScreen), findsOneWidget);
    expect(find.text('Operational assignment'), findsOneWidget);
  });

  testWidgets('Task 36 profile entry opens Security', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(
            config: _config,
            repository: _FixedProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('profile-security-entry'));
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(DriverSecurityScreen), findsOneWidget);
    expect(find.text('Account security'), findsWidgets);
  });
}
