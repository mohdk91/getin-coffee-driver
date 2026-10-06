import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';
import 'package:getin_driver/features/profile/domain/driver_profile_models.dart';
import 'package:getin_driver/features/profile/driver_profile_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

class _ProfileRepository implements DriverProfileRepository {
  @override
  DriverProfileDataSource get source => DriverProfileDataSource.demo;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    return DriverProfileLoadResult.success(
      DriverProfileSnapshot(
        fullName: 'Test Driver',
        phone: '+20 111 222 3333',
        email: 'driver@getin.test',
        driverId: 'DRV-261',
        verificationStatus: DriverProfileVerificationStatus.approved,
        assignedRegion: 'East Alexandria',
        assignedBranches: const ['Stanley', 'San Stefano'],
        updatedAt: DateTime(2026, 10, 6),
      ),
    );
  }
}

void main() {
  testWidgets('Task 261 Profile V2 keeps photo, identity and work summary',
      (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(
            config: _config,
            repository: _ProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Driver Profile'), findsOneWidget);
    expect(find.byKey(const Key('driver-profile-photo')), findsOneWidget);
    expect(find.text('Test Driver'), findsOneWidget);
    expect(find.text('Approved'), findsWidgets);
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('East Alexandria'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
