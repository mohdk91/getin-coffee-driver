import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/delivery/data/driver_start_delivery_repository.dart';
import 'package:getin_driver/features/delivery/driver_start_delivery_screen.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';

void main() {
  testWidgets('Task 264 surfaces customer arrival as the immediate next step',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const delivery = DriverActiveDeliverySummary(
      orderNumber: 'GD-264',
      status: 'Out for delivery',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 19,
      state: DriverDeliveryState.outForDelivery,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository: DemoDriverDeliveryDestinationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Arrived at Customer'),
        findsOneWidget);
  });

  testWidgets('Task 264 makes Start Delivery the pickup handoff next action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const delivery = DriverActiveDeliverySummary(
      orderNumber: 'GD-264',
      status: 'Picked up',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 19,
      state: DriverDeliveryState.pickedUp,
    );
    final route = DriverBranchRouteInfo(
      orderNumber: 'GD-264',
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
        home: DriverStartDeliveryScreen(
          config: config,
          delivery: delivery,
          route: route,
          repository: const DemoDriverStartDeliveryRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start Delivery'), findsOneWidget);
  });
}
