enum DriverNotificationDataSource { demo, api }

enum DriverNotificationCategory {
  newOrder,
  orderAcceptedElsewhere,
  orderUpdated,
  branchReady,
  customerMessage,
  cancellation,
  deliveryVerificationIssue,
  earnings,
  documentExpiry,
  system,
}

extension DriverNotificationCategoryPresentation on DriverNotificationCategory {
  String get label {
    return switch (this) {
      DriverNotificationCategory.newOrder => 'New Order',
      DriverNotificationCategory.orderAcceptedElsewhere =>
        'Order Accepted Elsewhere',
      DriverNotificationCategory.orderUpdated => 'Order Updated',
      DriverNotificationCategory.branchReady => 'Branch Ready',
      DriverNotificationCategory.customerMessage => 'Customer Message',
      DriverNotificationCategory.cancellation => 'Cancellation',
      DriverNotificationCategory.deliveryVerificationIssue =>
        'Delivery Verification Issue',
      DriverNotificationCategory.earnings => 'Earnings',
      DriverNotificationCategory.documentExpiry => 'Document Expiry',
      DriverNotificationCategory.system => 'System',
    };
  }
}

class DriverNotificationItem {
  final String id;
  final DriverNotificationCategory category;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? orderNumber;

  const DriverNotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.orderNumber,
  });

  DriverNotificationItem copyWith({bool? isRead}) {
    return DriverNotificationItem(
      id: id,
      category: category,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      orderNumber: orderNumber,
    );
  }
}

class DriverNotificationsSnapshot {
  final List<DriverNotificationItem> items;
  final DateTime updatedAt;

  const DriverNotificationsSnapshot({
    required this.items,
    required this.updatedAt,
  });

  int get unreadCount => items.where((item) => !item.isRead).length;

  Set<DriverNotificationCategory> get categories =>
      items.map((item) => item.category).toSet();
}

class DriverNotificationsLoadResult {
  final DriverNotificationsSnapshot? snapshot;
  final String? errorMessage;

  const DriverNotificationsLoadResult._({this.snapshot, this.errorMessage});

  const DriverNotificationsLoadResult.success(
    DriverNotificationsSnapshot snapshot,
  ) : this._(snapshot: snapshot);

  const DriverNotificationsLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}

class DriverNotificationMutationResult {
  final DriverNotificationsSnapshot? snapshot;
  final String? errorMessage;

  const DriverNotificationMutationResult._({this.snapshot, this.errorMessage});

  const DriverNotificationMutationResult.success(
    DriverNotificationsSnapshot snapshot,
  ) : this._(snapshot: snapshot);

  const DriverNotificationMutationResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}
