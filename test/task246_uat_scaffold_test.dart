import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/navigation/driver_tab.dart';
import 'package:getin_driver/core/widgets/driver_app_scaffold.dart';

void main() {
  testWidgets('Task 246 keeps test tooling out of the primary app chrome',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAppScaffold(
          currentTab: DriverTab.home,
          onTabChanged: (_) {},
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.text('Getin Driver'), findsOneWidget);
    expect(find.text('UAT'), findsNothing);
    expect(find.byTooltip('UAT incoming order'), findsNothing);
    expect(find.byIcon(Icons.science_outlined), findsNothing);
  });
}
