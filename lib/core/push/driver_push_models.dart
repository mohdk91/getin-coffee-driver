enum DriverPushOrigin {
  foreground,
  backgroundTap,
  terminatedTap,
}

class DriverPushIntent {
  final DriverPushOrigin origin;
  final String type;
  final String? notificationId;
  final String? actionRoute;
  final int? orderId;
  final String? orderNumber;
  final int? offerId;
  final DateTime? expiresAt;
  final String? title;
  final String? body;

  const DriverPushIntent({
    required this.origin,
    required this.type,
    this.notificationId,
    this.actionRoute,
    this.orderId,
    this.orderNumber,
    this.offerId,
    this.expiresAt,
    this.title,
    this.body,
  });

  factory DriverPushIntent.fromData({
    required DriverPushOrigin origin,
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) {
    int? parseInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    String? normalized(Object? value) {
      final text = value?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }

    final type = normalized(data['type']) ?? 'system';
    return DriverPushIntent(
      origin: origin,
      type: type,
      notificationId: normalized(data['notification_id']),
      actionRoute: normalized(data['action_route']),
      orderId: parseInt(data['order_id']),
      orderNumber: normalized(data['order_number']),
      offerId: parseInt(data['offer_id']),
      expiresAt: DateTime.tryParse(normalized(data['expires_at']) ?? ''),
      title: normalized(title),
      body: normalized(body),
    );
  }

  bool get isOrderOffer =>
      type.toLowerCase().replaceAll('-', '_') == 'order_available' ||
      actionRoute == 'driver/orders/new';

  String get displayMessage {
    final message = body?.trim();
    if (message != null && message.isNotEmpty) return message;
    if (isOrderOffer) return 'A new delivery is available.';
    return 'You have a new Getin notification.';
  }
}
