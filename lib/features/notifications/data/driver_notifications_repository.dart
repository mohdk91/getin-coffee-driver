import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_notification_models.dart';

abstract interface class DriverNotificationsRepository {
  DriverNotificationDataSource get source;
  Future<DriverNotificationsLoadResult> loadNotifications();
  Future<DriverNotificationMutationResult> markRead(String notificationId);
  Future<DriverNotificationMutationResult> markAllRead();
}

class DriverNotificationsRepositoryFactory {
  DriverNotificationsRepositoryFactory._();
  static DriverNotificationsRepository create(AppConfig config,
      {DriverApiContext? context}) {
    if (config.isApiConfigured) {
      return ApiDriverNotificationsRepository(
          context ?? DriverApiContext.create(config));
    }
    return config.allowsDemo
        ? DemoDriverNotificationsRepository()
        : const UnavailableDriverNotificationsRepository();
  }
}

class ApiDriverNotificationsRepository
    implements DriverNotificationsRepository {
  final DriverApiContext context;
  const ApiDriverNotificationsRepository(this.context);

  @override
  DriverNotificationDataSource get source => DriverNotificationDataSource.api;

  @override
  Future<DriverNotificationsLoadResult> loadNotifications() async {
    try {
      final envelope = await context.apiClient.getJson(
        '/v1/driver/notifications',
        query: const <String, Object?>{'per_page': 50},
        authenticated: true,
      );
      final items = DriverApiContext.nestedItems(envelope)
          .whereType<Map>()
          .map((raw) => _notification(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
      return DriverNotificationsLoadResult.success(
        DriverNotificationsSnapshot(items: items, updatedAt: DateTime.now()),
      );
    } on ApiException catch (error) {
      return DriverNotificationsLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverNotificationsLoadResult.failure(error.message);
    }
  }

  @override
  Future<DriverNotificationMutationResult> markRead(
      String notificationId) async {
    final id = int.tryParse(notificationId);
    if (id == null) {
      return const DriverNotificationMutationResult.failure(
          'Notification identifier is invalid.');
    }
    try {
      await context.apiClient
          .postJson('/v1/driver/notifications/$id/read', authenticated: true);
      return _refreshMutation();
    } on ApiException catch (error) {
      return DriverNotificationMutationResult.failure(error.message);
    }
  }

  @override
  Future<DriverNotificationMutationResult> markAllRead() async {
    try {
      await context.apiClient
          .postJson('/v1/driver/notifications/read-all', authenticated: true);
      return _refreshMutation();
    } on ApiException catch (error) {
      return DriverNotificationMutationResult.failure(error.message);
    }
  }

  Future<DriverNotificationMutationResult> _refreshMutation() async {
    final refreshed = await loadNotifications();
    if (!refreshed.isSuccess) {
      return DriverNotificationMutationResult.failure(
        refreshed.errorMessage ?? 'Could not refresh notifications.',
      );
    }
    return DriverNotificationMutationResult.success(refreshed.snapshot!);
  }

  DriverNotificationItem _notification(Map<String, dynamic> raw) {
    final data = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : const <String, dynamic>{};
    return DriverNotificationItem(
      id: raw['id']?.toString() ?? '',
      category: _category(raw['type']?.toString() ?? 'system'),
      title: raw['title']?.toString() ?? 'Getin notification',
      message: raw['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: raw['is_read'] == true,
      orderNumber:
          data['order_number']?.toString() ?? data['orderNumber']?.toString(),
    );
  }

  DriverNotificationCategory _category(String value) {
    final n = value.toLowerCase().replaceAll('-', '_');
    if (n.contains('new_order') || n.contains('order_available')) {
      return DriverNotificationCategory.newOrder;
    }
    if (n.contains('accepted_elsewhere') || n.contains('offer_taken')) {
      return DriverNotificationCategory.orderAcceptedElsewhere;
    }
    if (n.contains('branch_ready') || n.contains('pickup_ready')) {
      return DriverNotificationCategory.branchReady;
    }
    if (n.contains('customer_message') || n.contains('chat')) {
      return DriverNotificationCategory.customerMessage;
    }
    if (n.contains('cancel')) {
      return DriverNotificationCategory.cancellation;
    }
    if (n.contains('verification')) {
      return DriverNotificationCategory.deliveryVerificationIssue;
    }
    if (n.contains('earning') ||
        n.contains('payout') ||
        n.contains('commission')) {
      return DriverNotificationCategory.earnings;
    }
    if (n.contains('document') && n.contains('expir')) {
      return DriverNotificationCategory.documentExpiry;
    }
    if (n.contains('order')) {
      return DriverNotificationCategory.orderUpdated;
    }
    return DriverNotificationCategory.system;
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
