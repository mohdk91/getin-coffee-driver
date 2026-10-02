import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/responsive/responsive.dart';
import 'package:getin_driver/core/theme/app_theme.dart';
import 'package:getin_driver/core/widgets/getin_action_button.dart';

void main() {
  testWidgets('Task 244 driver action survives compact width and large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: GetinActionButton(
                label: 'Confirm pickup and continue to customer destination',
                icon: Icons.route_rounded,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(54));
  });

  testWidgets('Task 244 treats 360px-class devices as compact', (tester) async {
    bool? compact;
    double? padding;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: Builder(
            builder: (context) {
              compact = Responsive.isCompact(context);
              padding = Responsive.horizontalPadding(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(compact, isTrue);
    expect(padding, 14);
  });
}
