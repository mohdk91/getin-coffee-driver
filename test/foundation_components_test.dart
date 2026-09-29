import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/navigation/driver_tab.dart';
import 'package:getin_driver/core/widgets/connectivity_banner.dart';
import 'package:getin_driver/core/widgets/driver_app_scaffold.dart';

void main() {
  testWidgets('driver scaffold exposes four operational tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAppScaffold(
          currentTab: DriverTab.home,
          onTabChanged: (_) {},
          body: const SizedBox(),
        ),
      ),
    );
    for (final tab in DriverTab.values) {
      expect(find.text(tab.label), findsOneWidget);
    }
  });

  testWidgets('warning banner renders offline state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConnectivityBanner(
            tone: WarningBannerTone.offline,
            title: 'Offline',
            message: 'No network',
          ),
        ),
      ),
    );
    expect(find.text('Offline'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });
}
