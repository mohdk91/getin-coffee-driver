import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

Future<void> _scrollTo(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable).first;

  // The dashboard uses a lazy ListView. Scroll in small steps until the
  // requested Task #6 summary item has been built in the widget tree.
  for (var attempt = 0; attempt < 12; attempt++) {
    final target = find.text(text);
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
      return;
    }

    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pumpAndSettle();
  }

  expect(find.text(text), findsOneWidget);
}

void main() {
  testWidgets('home dashboard shows Task 6 operational summary',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(config: config),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Delivery in progress'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('ACTIVE DELIVERY'), findsOneWidget);
    expect(find.text('GD-2481'), findsOneWidget);

    await _scrollTo(tester, 'Available orders');
    expect(find.text('Available orders'), findsOneWidget);
    expect(find.text('Completed today'), findsOneWidget);
    expect(find.text('Earnings today'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);

    // Task #9 eligibility UI is covered by order_eligibility_widget_test.dart.
    // DriverHomeDashboard intentionally renders its eligibility entry point only
    // when an onOpenOrderEligibility callback is provided by the parent shell.
  });
}
