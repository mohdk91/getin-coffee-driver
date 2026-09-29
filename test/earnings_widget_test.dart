import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/earnings/driver_earnings_screen.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );

  testWidgets('Task 26 renders Today earnings and delivery breakdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverEarningsScreen(config: config)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today earnings'), findsOneWidget);
    expect(find.text('EGP 485.50'), findsOneWidget);
    expect(find.text('4 completed deliveries'), findsOneWidget);

    // Task 27 adds the commissions entry before the delivery list. On the
    // default widget-test viewport the first delivery card is therefore
    // lazily built only after scrolling.
    for (var i = 0; i < 6 && find.text('GD-2481').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
    }

    expect(find.text('GD-2481'), findsOneWidget);
    expect(find.text('Base earning'), findsWidgets);
    expect(find.text('Distance bonus'), findsWidgets);
    expect(find.text('Peak bonus'), findsWidgets);
    expect(find.text('Tip'), findsWidgets);
    expect(find.text('Adjustments'), findsWidgets);
    expect(find.text('Total driver earning'), findsWidgets);
  });

  testWidgets('Task 26 switches between Today Week and Month', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverEarningsScreen(config: config)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Week earnings'), findsOneWidget);
    expect(find.text('6 completed deliveries'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Month earnings'), findsOneWidget);
    expect(find.text('8 completed deliveries'), findsOneWidget);
  });
}
