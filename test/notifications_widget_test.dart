import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/notifications/driver_notifications_screen.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets(
      'Task 29 renders required categories and three demo unread alerts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverNotificationsScreen(config: config),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Driver alerts'), findsOneWidget);
    expect(find.text('3 unread notifications'), findsOneWidget);
    expect(find.text('New Order'), findsWidgets);
    expect(find.text('Order Accepted Elsewhere'), findsWidgets);
    expect(find.text('Order Updated'), findsWidgets);
    expect(find.text('Branch Ready'), findsWidgets);
    expect(find.text('Customer Message'), findsWidgets);
    expect(find.text('Cancellation'), findsWidgets);
    expect(find.text('Delivery Verification Issue'), findsWidgets);
    expect(find.text('Earnings'), findsWidgets);
    expect(find.text('Document Expiry'), findsWidgets);
    expect(find.text('System'), findsWidgets);
  });

  testWidgets('Task 29 mark all read updates visible unread state', (
    tester,
  ) async {
    int? unreadCount;

    await tester.pumpWidget(
      MaterialApp(
        home: DriverNotificationsScreen(
          config: config,
          onUnreadCountChanged: (count) => unreadCount = count,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unreadCount, 3);
    expect(find.text('Unread (3)'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(unreadCount, 0);
    expect(find.text('You are all caught up.'), findsOneWidget);
    expect(find.text('Unread (0)'), findsOneWidget);
    expect(find.text('All notifications marked as read.'), findsOneWidget);
  });
}
