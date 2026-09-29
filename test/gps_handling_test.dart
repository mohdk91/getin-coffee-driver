import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/data/driver_gps_gateway.dart';
import 'package:getin_driver/features/location/data/driver_location_repository.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';
import 'package:getin_driver/features/location/driver_location_service_region_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Future<void> _scrollTo(WidgetTester tester, String text) async {
  final listView = find.byType(ListView);
  expect(listView, findsOneWidget);

  for (var attempt = 0;
      attempt < 12 && find.text(text).evaluate().isEmpty;
      attempt++) {
    await tester.drag(listView, const Offset(0, -280));
    await tester.pumpAndSettle();
  }

  expect(find.text(text), findsWidgets);
}

void main() {
  group('Task 37 GPS gateway states', () {
    test('demo gateway exposes every required GPS handling state', () async {
      final gateway = DemoDriverGpsGateway();

      for (final issue in <DriverGpsHandlingIssue>[
        DriverGpsHandlingIssue.ready,
        DriverGpsHandlingIssue.locationDisabled,
        DriverGpsHandlingIssue.permissionDenied,
        DriverGpsHandlingIssue.backgroundPermissionDenied,
        DriverGpsHandlingIssue.staleLocation,
        DriverGpsHandlingIssue.inaccurateGps,
      ]) {
        gateway.setScenario(issue);
        final health = await gateway.check();
        expect(health.issue, issue);
      }
    });

    test('foreground permission retry can recover denied demo state', () async {
      final gateway = DemoDriverGpsGateway(
        scenario: DriverGpsHandlingIssue.permissionDenied,
      );

      final denied = await gateway.check();
      expect(denied.homeState, DriverGpsState.permissionDenied);

      final recovered = await gateway.check(requestPermission: true);
      expect(recovered.issue, DriverGpsHandlingIssue.ready);
      expect(recovered.homeState, DriverGpsState.ready);
    });

    test('location settings can recover disabled demo state', () async {
      final gateway = DemoDriverGpsGateway(
        scenario: DriverGpsHandlingIssue.locationDisabled,
      );

      expect((await gateway.check()).issue,
          DriverGpsHandlingIssue.locationDisabled);
      expect(await gateway.openLocationSettings(), isTrue);
      expect((await gateway.check()).issue, DriverGpsHandlingIssue.ready);
    });
  });

  testWidgets('Task 37 renders GPS diagnostics and ready state',
      (tester) async {
    final gateway = DemoDriverGpsGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverLocationServiceRegionScreen(
          config: _config,
          repository: const DemoDriverLocationRepository(),
          gpsGateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GPS handling'), findsOneWidget);
    expect(find.text('Location ready'), findsOneWidget);
    expect(find.text('GPS diagnostics'), findsOneWidget);

    await _scrollTo(tester, 'Background permission');
    expect(find.text('Granted'), findsWidgets);

    await _scrollTo(tester, 'Current GPS');
    expect(find.text('Current GPS'), findsOneWidget);
  });

  testWidgets('Task 37 permission denied state can retry to Ready',
      (tester) async {
    final gateway = DemoDriverGpsGateway(
      scenario: DriverGpsHandlingIssue.permissionDenied,
    );
    final emitted = <DriverGpsState>[];

    await tester.pumpWidget(
      MaterialApp(
        home: DriverLocationServiceRegionScreen(
          config: _config,
          repository: const DemoDriverLocationRepository(),
          gpsGateway: gateway,
          onGpsStateChanged: emitted.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location permission denied'), findsOneWidget);
    expect(emitted.last, DriverGpsState.permissionDenied);

    await tester.tap(find.text('Grant location permission'));
    await tester.pumpAndSettle();

    expect(find.text('Location ready'), findsOneWidget);
    expect(emitted.last, DriverGpsState.ready);
  });

  testWidgets('Task 37 demo scenarios include stale and inaccurate GPS',
      (tester) async {
    final gateway = DemoDriverGpsGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverLocationServiceRegionScreen(
          config: _config,
          repository: const DemoDriverLocationRepository(),
          gpsGateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, 'Demo GPS scenarios');
    expect(find.text('Location disabled'), findsOneWidget);
    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('Background denied'), findsOneWidget);
    expect(find.text('Stale'), findsOneWidget);
    expect(find.text('Inaccurate'), findsOneWidget);
  });
}
