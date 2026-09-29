import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery/data/driver_start_delivery_repository.dart';
import 'package:getin_driver/features/delivery/domain/driver_start_delivery_models.dart';
import 'package:getin_driver/features/delivery/driver_start_delivery_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-2481',
    status: 'Picked up • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  DriverBranchRouteInfo route() => DriverBranchRouteInfo(
        orderNumber: 'GD-2481',
        branchName: 'Stanley',
        branchImageAsset: 'assets/images/branches/getin_stanley.png',
        branchAddress: 'Stanley, Alexandria, Egypt',
        branchPhoneLabel: 'Demo',
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
        pickupInstructions: const [],
        updatedAt: DateTime(2026, 9, 25, 20),
      );

  testWidgets('Task 15 explicitly starts delivery after pickup',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    DriverStartDeliveryReceipt? callbackReceipt;

    await tester.pumpWidget(
      MaterialApp(
        home: DriverStartDeliveryScreen(
          config: config,
          delivery: delivery,
          route: route(),
          repository: const DemoDriverStartDeliveryRepository(),
          onDeliveryStarted: (value) => callbackReceipt = value,
        ),
      ),
    );

    expect(find.text('Start Delivery'), findsWidgets);
    expect(find.textContaining('Laravel and the Customer App are not updated'),
        findsOneWidget);

    final button = find.widgetWithText(FilledButton, 'Start Delivery');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Delivery started'), findsOneWidget);
    expect(find.textContaining('not acknowledged by Laravel'), findsOneWidget);
    expect(callbackReceipt, isNotNull);
    expect(callbackReceipt!.serverAcknowledged, isFalse);
  });

  testWidgets('Task 15 API-unavailable path does not fake state change',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverStartDeliveryScreen(
          config: config,
          delivery: delivery,
          route: route(),
          repository: const UnavailableDriverStartDeliveryRepository(),
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'Start Delivery');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.textContaining('status has not changed'), findsOneWidget);
    expect(find.text('Delivery started'), findsNothing);
  });
}
