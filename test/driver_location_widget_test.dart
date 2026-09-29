import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/location/data/driver_gps_gateway.dart';
import 'package:getin_driver/features/location/data/driver_location_repository.dart';
import 'package:getin_driver/features/location/driver_location_service_region_screen.dart';

const config = AppConfig(
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
  testWidgets('Task 8 screen shows GPS and service assignment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverLocationServiceRegionScreen(
          config: config,
          repository: const DemoDriverLocationRepository(),
          gpsGateway: DemoDriverGpsGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('GPS & Service Region'), findsOneWidget);
    expect(find.text('GPS handling'), findsOneWidget);
    expect(find.textContaining('Development mode.'), findsOneWidget);

    await _scrollTo(tester, 'Current GPS');
    expect(find.text('Current GPS'), findsOneWidget);

    await _scrollTo(tester, 'Service assignment');
    expect(find.text('Service assignment'), findsOneWidget);
    expect(find.text('Egypt'), findsOneWidget);
    expect(find.text('Alexandria'), findsOneWidget);

    await _scrollTo(tester, 'Allowed branches');
    expect(find.text('Allowed branches'), findsOneWidget);
    expect(find.text('Stanley'), findsOneWidget);
    expect(find.text('Gleem'), findsOneWidget);
    expect(find.text('8 km'), findsOneWidget);
    expect(find.text('Motorbike'), findsOneWidget);
  });

  testWidgets('non-demo repository shows unavailable state instead of fake GPS',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverLocationServiceRegionScreen(
          config: AppConfig(
            environment: AppEnvironment.production,
            apiBaseUrl: 'https://api.example.test',
          ),
          repository: UnavailableDriverLocationRepository(),
          gpsGateway: UnavailableDriverGpsGateway(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Location profile unavailable'), findsOneWidget);
    expect(find.textContaining('not connected'), findsOneWidget);
  });
}
