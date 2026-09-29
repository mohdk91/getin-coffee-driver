import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/route/data/driver_branch_route_repository.dart';
import 'package:getin_driver/features/route/driver_route_to_branch_screen.dart';

Future<void> _dragUntilBuilt(
  WidgetTester tester,
  Finder target,
) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -280));
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

  testWidgets('Task 15 shows Start Delivery only after pickup status',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverRouteToBranchScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverBranchRouteRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final startButton = find.widgetWithText(FilledButton, 'Start Delivery');
    await _dragUntilBuilt(tester, startButton);

    expect(find.text('Pickup complete'), findsOneWidget);
    expect(find.text('Arrived at Branch • Verify Pickup'), findsNothing);
  });
}
