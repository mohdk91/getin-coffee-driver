import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
import 'package:getin_driver/features/pickup/data/driver_branch_pickup_repository.dart';
import 'package:getin_driver/features/pickup/driver_branch_pickup_verification_screen.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

DriverBranchRouteInfo _route() {
  return DriverBranchRouteInfo(
    orderNumber: 'GD-3101',
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
    updatedAt: DateTime(2026, 9, 25),
  );
}

Future<void> _pumpPickup(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: DriverBranchPickupVerificationScreen(
        config: _config,
        route: _route(),
        repository: const DemoDriverBranchPickupRepository(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Task 13 keeps Received from Branch locked before verification',
      (tester) async {
    await _pumpPickup(tester);

    expect(find.text('Branch Pickup'), findsOneWidget);
    expect(find.text('GD-3101'), findsOneWidget);
    expect(find.text('Scan Branch QR'), findsOneWidget);
    expect(find.text('Verify Token'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Received from Branch'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Task 13 token verification enables branch receipt',
      (tester) async {
    await _pumpPickup(tester);

    await tester.enterText(find.byType(TextField), '2468');
    await tester.tap(find.text('Verify Token'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pickup verified with Pickup token'),
        findsOneWidget);

    final receive = find.widgetWithText(
      FilledButton,
      'Received from Branch',
    );
    expect(receive, findsOneWidget);
    await tester.scrollUntilVisible(
      receive,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(receive);
    await tester.pumpAndSettle();

    expect(find.text('Pickup recorded'), findsOneWidget);
    expect(find.textContaining('did not update Laravel'), findsOneWidget);
    expect(find.textContaining('DEMO-PICKUP-GD-3101'), findsOneWidget);
  });

  testWidgets('Task 13 demo QR path verifies without claiming camera is live',
      (tester) async {
    await _pumpPickup(tester);

    await tester.tap(find.text('Scan Branch QR'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Pickup verified with Branch QR'), findsOneWidget);
    expect(
        find.textContaining(
            'Camera integration is not being presented as live'),
        findsOneWidget);
  });
}
