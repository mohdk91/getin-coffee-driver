import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/navigation/driver_tab.dart';
import 'package:getin_driver/core/widgets/driver_app_scaffold.dart';

void main() {
  testWidgets('Task 246 UAT scaffold clearly labels and exposes demo trigger',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAppScaffold(
          currentTab: DriverTab.home,
          onTabChanged: (_) {},
          onUatIncomingOrder: () {},
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.text('UAT'), findsOneWidget);
    expect(find.byTooltip('UAT incoming order'), findsOneWidget);
  });
}
