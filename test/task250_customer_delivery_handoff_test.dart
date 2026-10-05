import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/delivery/data/driver_start_delivery_repository.dart';
import 'package:getin_driver/features/delivery/domain/driver_start_delivery_models.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';
import 'package:getin_driver/features/route/data/driver_branch_route_repository.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PickedUpHomeRepository implements DriverHomeRepository {
  const _PickedUpHomeRepository();

  @override
  DriverHomeDataSource get source => DriverHomeDataSource.demo;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    return DriverHomeLoadResult.success(
      DriverHomeSnapshot(
        availability: DriverAvailabilityState.online,
        activeDelivery: const DriverActiveDeliverySummary(
          orderNumber: 'GD-UAT-9001',
          status: 'Picked up • Demo',
          pickupBranch: 'Stanley',
          destinationArea: 'San Stefano',
          etaMinutes: 19,
          state: DriverDeliveryState.pickedUp,
        ),
        availableOrders: 0,
        completedToday: 0,
        earningsToday: 0,
        currencyCode: 'EGP',
        rating: 4.9,
        ratingCount: 126,
        unreadNotifications: 0,
        gpsState: DriverGpsState.ready,
        internetConnected: true,
        updatedAt: DateTime(2026, 10, 6, 1, 20),
      ),
    );
  }
}

class _ImmediateRouteRepository implements DriverBranchRouteRepository {
  const _ImmediateRouteRepository();

  @override
  DriverBranchRouteDataSource get source => DriverBranchRouteDataSource.demo;

  @override
  Future<DriverBranchRouteLoadResult> load({
    required DriverActiveDeliverySummary delivery,
  }) async {
    return DriverBranchRouteLoadResult.success(
      DriverBranchRouteInfo(
        orderNumber: delivery.orderNumber,
        branchName: 'Stanley',
        branchImageAsset: 'assets/images/branches/getin_stanley.png',
        branchAddress: 'Alexandria, Egypt',
        branchPhoneLabel: 'Demo',
        branchCoordinates:
            const DriverCoordinates(latitude: 31.2397, longitude: 29.9489),
        driverCoordinates:
            const DriverCoordinates(latitude: 31.2458, longitude: 29.9668),
        etaMinutes: 19,
        distanceKm: 2.1,
        pickupInstructions: const <String>[],
        updatedAt: DateTime(2026, 10, 6, 1, 20),
      ),
    );
  }

  @override
  Future<String?> arriveAtBranch({
    required DriverActiveDeliverySummary delivery,
  }) async => null;
}

class _ImmediateStartDeliveryRepository
    implements DriverStartDeliveryRepository {
  const _ImmediateStartDeliveryRepository();

  @override
  DriverStartDeliveryDataSource get source => DriverStartDeliveryDataSource.demo;

  @override
  Future<DriverStartDeliveryResult> startDelivery({
    required int? apiOrderId,
    required String orderNumber,
    required double? latitude,
    required double? longitude,
  }) async {
    return DriverStartDeliveryResult.success(
      DriverStartDeliveryReceipt(
        auditId: 'DEMO-START-$orderNumber',
        orderNumber: orderNumber,
        driverId: 'DEMO-DRIVER-001',
        startedAt: DateTime(2026, 10, 6, 1, 25),
        latitude: latitude,
        longitude: longitude,
        serverAcknowledged: false,
        isDemo: true,
      ),
    );
  }
}

Future<void> _dragUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 18 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
      'Task 250 Start Delivery replaces confirmation with customer destination flow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverFoundationShell(
          config: AppConfig(
            environment: AppEnvironment.development,
            apiBaseUrl: '',
          ),
          homeRepository: _PickedUpHomeRepository(),
          routeRepository: _ImmediateRouteRepository(),
          startDeliveryRepository: _ImmediateStartDeliveryRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resume Delivery'));
    await tester.pumpAndSettle();

    final routeStart = find.widgetWithText(FilledButton, 'Start Delivery');
    await _dragUntilBuilt(tester, routeStart);
    await tester.tap(routeStart);
    await tester.pumpAndSettle();

    final confirmStart = find.widgetWithText(FilledButton, 'Start Delivery');
    expect(confirmStart, findsOneWidget);
    await tester.tap(confirmStart);
    await tester.pumpAndSettle();

    expect(find.byType(DriverDeliveryNavigationScreen), findsOneWidget);
    expect(find.text('Delivery Destination'), findsWidgets);
    expect(find.text('GD-UAT-9001'), findsOneWidget);
    expect(find.text('OUT FOR DELIVERY'), findsOneWidget);
    expect(find.text('San Stefano'), findsWidgets);

    // The arrival card sits below destination, timeline, navigation and contact
    // sections in a lazy ListView. Scroll it into the widget tree before
    // asserting the handoff action exists.
    final arrival = find.widgetWithText(FilledButton, 'Arrived at Customer');
    await _dragUntilBuilt(tester, arrival);
    expect(arrival, findsOneWidget);
    expect(find.textContaining('next Driver task'), findsNothing);
  });
}
