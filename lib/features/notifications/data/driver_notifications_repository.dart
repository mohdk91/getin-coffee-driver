import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_notification_models.dart';

abstract interface class DriverNotificationsRepository {
  DriverNotificationDataSource get source;

  Future<DriverNotificationsLoadResult> loadNotifications();

  Future<DriverNotificationMutationResult> markRead(String notificationId);

  Future<DriverNotificationMutationResult> markAllRead();
}

class DriverNotificationsRepositoryFactory {
  DriverNotificationsRepositoryFactory._();

  static DriverNotificationsRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? DemoDriverNotificationsRepository()
        : const UnavailableDriverNotificationsRepository();
  }
}

class DemoDriverNotificationsRepository
    implements DriverNotificationsRepository {
  List<DriverNotificationItem>? _items;

  @override
  DriverNotificationDataSource get source => DriverNotificationDataSource.demo;

  List<DriverNotificationItem> _seedItems() {
    final now = DateTime.now();
    return [
      DriverNotificationItem(
        id: 'notification-new-order',
        category: DriverNotificationCategory.newOrder,
        title: 'New delivery available',
        message: 'A new eligible order is available from Stanley branch.',
        createdAt: now.subtract(const Duration(minutes: 4)),
        isRead: false,
        orderNumber: 'GD-3104',
      ),
      DriverNotificationItem(
        id: 'notification-customer-message',
        category: DriverNotificationCategory.customerMessage,
        title: 'Customer sent a message',
        message: 'The customer added a message to your active delivery.',
        createdAt: now.subtract(const Duration(minutes: 11)),
        isRead: false,
        orderNumber: 'GD-2481',
      ),
      DriverNotificationItem(
        id: 'notification-branch-ready',
        category: DriverNotificationCategory.branchReady,
        title: 'Pickup is ready',
        message: 'Stanley branch marked the active order ready for pickup.',
        createdAt: now.subtract(const Duration(minutes: 19)),
        isRead: false,
        orderNumber: 'GD-2481',
      ),
      DriverNotificationItem(
        id: 'notification-order-accepted-elsewhere',
        category: DriverNotificationCategory.orderAcceptedElsewhere,
        title: 'Order is no longer available',
        message:
            'Another driver accepted this delivery before your request completed.',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 8)),
        isRead: true,
        orderNumber: 'GD-3098',
      ),
      DriverNotificationItem(
        id: 'notification-order-updated',
        category: DriverNotificationCategory.orderUpdated,
        title: 'Delivery details updated',
        message: 'The delivery instructions were updated for this order.',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
        orderNumber: 'GD-2476',
      ),
      DriverNotificationItem(
        id: 'notification-cancellation',
        category: DriverNotificationCategory.cancellation,
        title: 'Order cancelled',
        message: 'This order was cancelled before branch pickup.',
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: true,
        orderNumber: 'GD-2451',
      ),
      DriverNotificationItem(
        id: 'notification-verification',
        category: DriverNotificationCategory.deliveryVerificationIssue,
        title: 'Verification needs attention',
        message:
            'A recent delivery verification attempt could not be confirmed.',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        isRead: true,
        orderNumber: 'GD-2442',
      ),
      DriverNotificationItem(
        id: 'notification-earnings',
        category: DriverNotificationCategory.earnings,
        title: 'Earnings updated',
        message: 'A completed delivery earning was added to your daily total.',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
        orderNumber: 'GD-2476',
      ),
      DriverNotificationItem(
        id: 'notification-document-expiry',
        category: DriverNotificationCategory.documentExpiry,
        title: 'Document expiry reminder',
        message: 'A driver document will need renewal soon.',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      DriverNotificationItem(
        id: 'notification-system',
        category: DriverNotificationCategory.system,
        title: 'Driver app notice',
        message: 'A system notice is available for your driver account.',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  DriverNotificationsSnapshot _snapshot() {
    _items ??= _seedItems();
    return DriverNotificationsSnapshot(
      items: List<DriverNotificationItem>.unmodifiable(_items!),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<DriverNotificationsLoadResult> loadNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return DriverNotificationsLoadResult.success(_snapshot());
  }

  @override
  Future<DriverNotificationMutationResult> markRead(
    String notificationId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 70));
    _items ??= _seedItems();
    final index = _items!.indexWhere((item) => item.id == notificationId);
    if (index < 0) {
      return const DriverNotificationMutationResult.failure(
        'Notification could not be found.',
      );
    }
    _items![index] = _items![index].copyWith(isRead: true);
    return DriverNotificationMutationResult.success(_snapshot());
  }

  @override
  Future<DriverNotificationMutationResult> markAllRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 70));
    _items ??= _seedItems();
    _items = [
      for (final item in _items!) item.copyWith(isRead: true),
    ];
    return DriverNotificationMutationResult.success(_snapshot());
  }
}

class UnavailableDriverNotificationsRepository
    implements DriverNotificationsRepository {
  const UnavailableDriverNotificationsRepository();

  @override
  DriverNotificationDataSource get source => DriverNotificationDataSource.api;

  @override
  Future<DriverNotificationsLoadResult> loadNotifications() async {
    return const DriverNotificationsLoadResult.failure(
      'Driver notifications are not connected to the Laravel API yet. Getin will not invent production notifications.',
    );
  }

  @override
  Future<DriverNotificationMutationResult> markRead(
    String notificationId,
  ) async {
    return const DriverNotificationMutationResult.failure(
      'Notification read state cannot be changed until the Laravel notifications API is connected.',
    );
  }

  @override
  Future<DriverNotificationMutationResult> markAllRead() async {
    return const DriverNotificationMutationResult.failure(
      'Notification read state cannot be changed until the Laravel notifications API is connected.',
    );
  }
}
