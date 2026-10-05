import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/storage/onboarding_preference_store.dart';
import 'package:getin_driver/features/foundation/driver_foundation_shell.dart';
import 'package:getin_driver/features/onboarding/driver_onboarding_screen.dart';
import 'package:getin_driver/features/order_history/driver_order_history_screen.dart';
import 'package:getin_driver/features/profile/driver_profile_screen.dart';

class _MemoryCompletionStore implements OnboardingCompletionStore {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets('driver shell renders Task 6 home and four primary tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DriverFoundationShell(config: _config)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Getin Driver'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Delivery in progress'), findsOneWidget);
    expect(find.text('Active delivery • GD-2481'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DriverOrderHistoryScreen),
        matching: find.text('Orders'),
      ),
      findsOneWidget,
    );
    expect(find.text('New / Available'), findsOneWidget);
    expect(find.text('Active / On Delivery'), findsOneWidget);
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.byTooltip('Filters'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('Active / On Delivery'));
    await tester.pumpAndSettle();
    expect(find.textContaining('GD-2481'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(DriverProfileScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DriverProfileScreen),
        matching: find.text('Driver Profile'),
      ),
      findsOneWidget,
    );
    expect(find.text('Demo Driver'), findsOneWidget);
  });

  testWidgets('onboarding contains five topics and finishes at Driver Login', (
    tester,
  ) async {
    final store = _MemoryCompletionStore();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverOnboardingScreen(
          config: _config,
          completionStore: store,
        ),
      ),
    );

    expect(find.text('Drive with Getin'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Follow the Flow'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Stay on Route'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Never Miss an Update'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Every Delivery'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(store.completed, isTrue);
    expect(find.text('Driver Login'), findsOneWidget);
  });
}
