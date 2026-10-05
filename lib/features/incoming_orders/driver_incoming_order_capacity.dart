class DriverIncomingOrderCapacity {
  final int activeOrderCount;
  final int maxActiveOrders;

  const DriverIncomingOrderCapacity({
    required this.activeOrderCount,
    this.maxActiveOrders = 1,
  });

  bool get canReceiveOffer => activeOrderCount < maxActiveOrders;

  String get blockedMessage =>
      'Finish your active delivery before receiving another order.';
}
