import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/destination/data/driver_delivery_destination_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/navigation/data/driver_navigation_launcher.dart';
import 'package:getin_driver/features/navigation/data/driver_navigation_preference_store.dart';
import 'package:getin_driver/features/navigation/domain/driver_navigation_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLauncher implements DriverNavigationLauncher {
  @override
  final DriverNavigationPlatform platform = DriverNavigationPlatform.android;

  DriverNavigationTarget? lastTarget;

  @override
  Future<DriverNavigationLaunchResult> launch({
    required DriverNavigationApp app,
    required DriverNavigationTarget target,
  }) async {
    lastTarget = target;
    return const DriverNavigationLaunchResult.success();
  }
}

class _MemoryPreferenceStore implements DriverNavigationPreferenceStore {
  @override
  Future<DriverNavigationApp> loadPreferredApp() async =>
      DriverNavigationApp.systemDefault;

  @override
  Future<void> savePreferredApp(DriverNavigationApp app) async {}
}

Future<void> _dragUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -250));
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

  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-2481',
    status: 'Out for delivery • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  testWidgets('Task 18 shows exact accepted-order destination and instructions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository: DemoDriverDeliveryDestinationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery Destination'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Abdel Salam Aref St, San Stefano, Alexandria'),
        findsOneWidget);
    expect(find.text('Building'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Floor'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Apartment'), findsOneWidget);
    expect(find.text('12B'), findsOneWidget);
    expect(find.text('Delivery instructions'), findsOneWidget);
    expect(find.textContaining('sample data only'), findsOneWidget);

    final exactPin = find.text('Exact delivery pin');
    await _dragUntilBuilt(tester, exactPin);
  });

  testWidgets('Task 18 navigation uses the exact delivery pin', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launcher = _FakeLauncher();
    final preferences = _MemoryPreferenceStore();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository:
              const DemoDriverDeliveryDestinationRepository(),
          launcher: launcher,
          preferenceStore: preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final openNavigation = find.text('Open Navigation');
    await _dragUntilBuilt(tester, openNavigation);
    await tester.tap(openNavigation);
    await tester.pumpAndSettle();

    expect(launcher.lastTarget?.label, 'Home');
    expect(launcher.lastTarget?.latitude, closeTo(31.24555, 0.000001));
    expect(launcher.lastTarget?.longitude, closeTo(29.96728, 0.000001));
  });

  testWidgets('Task 18 does not invent exact production destination',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: delivery,
          destinationRepository:
              UnavailableDriverDeliveryDestinationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exact destination unavailable'), findsOneWidget);
    expect(find.textContaining('will not invent'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
