import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/widgets/driver_v2_ui.dart';

void main() {
  testWidgets(
      'Task 257 shared Driver V2 cards render compact actions and stats',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DriverSectionHeading(
                title: 'Today',
                subtitle: 'Your shift at a glance',
              ),
              DriverQuickActionTile(
                label: 'Orders',
                caption: 'Open jobs',
                icon: Icons.receipt_long_outlined,
              ),
              DriverStatTile(
                label: 'Deliveries',
                value: '4',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
