import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
import 'package:getin_driver/features/pickup/data/driver_branch_pickup_repository.dart';
import 'package:getin_driver/features/pickup/driver_branch_pickup_verification_screen.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';

void main() {
  testWidgets('Task 263 makes verification the branch-pickup next action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    final route = DriverBranchRouteInfo(
      orderNumber: 'GD-263',
      branchName: 'Stanley',
      branchImageAsset: 'assets/images/branches/getin_stanley.png',
      branchAddress: 'Stanley, Alexandria, Egypt',
      branchPhoneLabel: 'Operations number',
      branchCoordinates: const DriverCoordinates(
        latitude: 31.2397,
        longitude: 29.9489,
      ),
      driverCoordinates: const DriverCoordinates(
        latitude: 31.2458,
        longitude: 29.9668,
      ),
      etaMinutes: 19,
      distanceKm: 2.1,
      pickupInstructions: const ['Confirm the order before leaving.'],
      updatedAt: DateTime(2026, 10, 6),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DriverBranchPickupVerificationScreen(
          config: config,
          route: route,
          repository: const DemoDriverBranchPickupRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.text('Verify the branch handoff'), findsOneWidget);
    expect(find.text('Scan Branch QR'), findsOneWidget);
    expect(find.text('Verify Token'), findsOneWidget);
  });
}
