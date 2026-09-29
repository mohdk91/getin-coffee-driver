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

  testWidgets('Task 12 route screen shows pickup route without Task 13 action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const delivery = DriverActiveDeliverySummary(
      orderNumber: 'GD-3101',
      status: 'Accepted',
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

    expect(find.text('Route to Branch'), findsOneWidget);
    expect(find.text('Stanley'), findsWidgets);
    expect(find.text('GD-3101'), findsOneWidget);
    expect(find.text('MAP PREVIEW'), findsOneWidget);
    expect(find.text('Open Navigation'), findsOneWidget);
    expect(find.text('Choose Navigation App'), findsOneWidget);
    expect(find.text('19 min'), findsOneWidget);

    final callBranch = find.text('Call Branch');
    await _dragUntilBuilt(tester, callBranch);
    expect(find.text('Support'), findsOneWidget);

    final orderContents = find.text('View Order Contents');
    await _dragUntilBuilt(tester, orderContents);
    expect(find.text('Received from Branch'), findsNothing);
  });

  testWidgets('Task 12 Call Branch is transparent demo behavior',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const delivery = DriverActiveDeliverySummary(
      orderNumber: 'GD-3101',
      status: 'Accepted',
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

    final callBranch = find.text('Call Branch');
    await _dragUntilBuilt(tester, callBranch);
    await tester.tap(callBranch);
    await tester.pump();

    expect(find.textContaining('No call was placed'), findsOneWidget);
  });
}
