import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/widgets/driver_app_scaffold.dart';
import 'package:getin_driver/core/navigation/driver_tab.dart';

void main() {
  test('Task 281 production config keeps demo and Test Lab disabled', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://portal.getincoffee.com/api',
      uatDemoRequested: true,
    );

    expect(config.allowsDemo, isFalse);
    expect(config.testLabEnabled, isFalse);
    expect(config.requiresApi, isTrue);
    expect(config.isApiTransportAllowed, isTrue);
  });

  test('Task 281 key production earning copy contains no backend plumbing', () {
    final repository = File(
      'lib/features/commissions/data/driver_commission_repository.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/commissions/driver_commissions_screen.dart',
    ).readAsStringSync();

    expect(repository, isNot(contains('immutable Laravel earning')));
    expect(repository, isNot(contains('backend-owned')));
    expect(screen, isNot(contains('Until replaced by backend')));
  });

  testWidgets(
      'Task 281 primary shell isolates body repaint and navigation semantics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAppScaffold(
          currentTab: DriverTab.home,
          onTabChanged: (_) {},
          body: const Text('Audit body'),
        ),
      ),
    );

    expect(
      find.byKey(const Key('driver-primary-body-repaint-boundary')),
      findsOneWidget,
    );
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
