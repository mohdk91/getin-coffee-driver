import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/notifications/data/driver_notifications_repository.dart';
import 'package:getin_driver/features/notifications/domain/driver_notification_models.dart';

void main() {
  test('Task 29 demo exposes every required notification category', () async {
    final repository = DemoDriverNotificationsRepository();

    final result = await repository.loadNotifications();

    expect(result.isSuccess, isTrue);
    final snapshot = result.snapshot!;
    expect(snapshot.items.length, 10);
    expect(snapshot.unreadCount, 3);
    expect(
      snapshot.categories,
      containsAll(DriverNotificationCategory.values),
    );
  });

  test('Task 29 demo read state can update one or all notifications', () async {
    final repository = DemoDriverNotificationsRepository();
    final initial = (await repository.loadNotifications()).snapshot!;
    final firstUnread = initial.items.firstWhere((item) => !item.isRead);

    final oneRead = await repository.markRead(firstUnread.id);
    expect(oneRead.isSuccess, isTrue);
    expect(oneRead.snapshot!.unreadCount, 2);

    final allRead = await repository.markAllRead();
    expect(allRead.isSuccess, isTrue);
    expect(allRead.snapshot!.unreadCount, 0);
    expect(allRead.snapshot!.items.every((item) => item.isRead), isTrue);
  });

  test('Task 29 production repository never invents notifications', () async {
    const repository = UnavailableDriverNotificationsRepository();

    final result = await repository.loadNotifications();

    expect(result.isSuccess, isFalse);
    expect(result.snapshot, isNull);
    expect(result.errorMessage, contains('not connected to the Laravel API'));
  });
}
