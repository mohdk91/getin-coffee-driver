import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/navigation/data/driver_navigation_launcher.dart';
import 'package:getin_driver/features/navigation/data/driver_navigation_preference_store.dart';
import 'package:getin_driver/features/navigation/domain/driver_navigation_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';
import 'package:getin_driver/features/navigation/driver_navigation_card.dart';

class _FakeNavigationLauncher implements DriverNavigationLauncher {
  @override
  final DriverNavigationPlatform platform = DriverNavigationPlatform.android;

  DriverNavigationApp? lastApp;
  DriverNavigationTarget? lastTarget;

  @override
  Future<DriverNavigationLaunchResult> launch({
    required DriverNavigationApp app,
    required DriverNavigationTarget target,
  }) async {
    lastApp = app;
    lastTarget = target;
    return const DriverNavigationLaunchResult.success();
  }
}

class _MemoryNavigationPreferenceStore
    implements DriverNavigationPreferenceStore {
  DriverNavigationApp value;

  _MemoryNavigationPreferenceStore([
    this.value = DriverNavigationApp.systemDefault,
  ]);

  @override
  Future<DriverNavigationApp> loadPreferredApp() async => value;

  @override
  Future<void> savePreferredApp(DriverNavigationApp app) async {
    value = app;
  }
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

class _OutForDeliveryHomeRepository implements DriverHomeRepository {
  const _OutForDeliveryHomeRepository();

  @override
  DriverHomeDataSource get source => DriverHomeDataSource.demo;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    return DriverHomeLoadResult.success(
      DriverHomeSnapshot(
        availability: DriverAvailabilityState.online,
        activeDelivery: const DriverActiveDeliverySummary(
          orderNumber: 'GD-2481',
          status: 'Out for delivery • Demo',
          pickupBranch: 'Stanley',
          destinationArea: 'San Stefano',
          etaMinutes: 19,
        ),
        availableOrders: 0,
        completedToday: 7,
        earningsToday: 485.5,
        currencyCode: 'EGP',
        rating: 4.9,
        ratingCount: 126,
        unreadNotifications: 0,
        gpsState: DriverGpsState.ready,
        internetConnected: true,
        updatedAt: DateTime(2026, 9, 26),
      ),
    );
  }
}

void main() {
  testWidgets('Task 16 opens the saved preferred navigation app',
      (tester) async {
    final launcher = _FakeNavigationLauncher();
    final preferences = _MemoryNavigationPreferenceStore(
      DriverNavigationApp.googleMaps,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverNavigationCard(
            target: const DriverNavigationTarget(
              label: 'Stanley',
              address: 'Stanley, Alexandria, Egypt',
              latitude: 31.2397,
              longitude: 29.9489,
            ),
            launcher: launcher,
            preferenceStore: preferences,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google Maps'), findsOneWidget);
    await tester.tap(find.text('Open Navigation'));
    await tester.pumpAndSettle();

    expect(launcher.lastApp, DriverNavigationApp.googleMaps);
    expect(launcher.lastTarget?.label, 'Stanley');
  });

  testWidgets('Task 16 app chooser saves Google Maps and launches it',
      (tester) async {
    final launcher = _FakeNavigationLauncher();
    final preferences = _MemoryNavigationPreferenceStore();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverNavigationCard(
            target: const DriverNavigationTarget(
              label: 'Stanley',
              address: 'Stanley, Alexandria, Egypt',
              latitude: 31.2397,
              longitude: 29.9489,
            ),
            launcher: launcher,
            preferenceStore: preferences,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose Navigation App'));
    await tester.pumpAndSettle();

    expect(find.text('System default'), findsWidgets);
    expect(find.text('Google Maps'), findsOneWidget);
    expect(find.text('Apple Maps'), findsOneWidget);
    expect(find.text('Available on iPhone and iPad.'), findsOneWidget);

    await tester.tap(find.text('Google Maps'));
    await tester.pumpAndSettle();

    expect(preferences.value, DriverNavigationApp.googleMaps);
    expect(launcher.lastApp, DriverNavigationApp.googleMaps);
  });

  testWidgets('Task 16 navigation remains available with Task 18 destination',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launcher = _FakeNavigationLauncher();
    final preferences = _MemoryNavigationPreferenceStore();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryNavigationScreen(
          delivery: const DriverActiveDeliverySummary(
            orderNumber: 'GD-2481',
            status: 'Out for delivery • Demo',
            pickupBranch: 'Stanley',
            destinationArea: 'San Stefano',
            etaMinutes: 19,
          ),
          launcher: launcher,
          preferenceStore: preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery Destination'), findsWidgets);
    expect(find.text('San Stefano'), findsWidgets);
    final openNavigation = find.text('Open Navigation');
    await _dragUntilBuilt(tester, openNavigation);
  });

  testWidgets(
      'Task 16 resume opens destination navigation after delivery starts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launcher = _FakeNavigationLauncher();
    final preferences = _MemoryNavigationPreferenceStore();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverFoundationShell(
          config: const AppConfig(
            environment: AppEnvironment.development,
            apiBaseUrl: '',
          ),
          homeRepository: const _OutForDeliveryHomeRepository(),
          navigationLauncher: launcher,
          navigationPreferenceStore: preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final resume = find.text('Resume Delivery');
    expect(resume, findsOneWidget);
    await tester.tap(resume);
    await tester.pumpAndSettle();

    expect(find.text('Delivery Destination'), findsWidgets);
    expect(find.text('San Stefano'), findsWidgets);
    final openNavigation = find.text('Open Navigation');
    await _dragUntilBuilt(tester, openNavigation);
  });
}
