import '../../active_delivery/domain/driver_delivery_state_machine.dart';

enum DriverOrderHistoryDataSource { demo, api }

enum DriverOrderHistoryDateFilter { all, today, last7Days, last30Days }

extension DriverOrderHistoryDateFilterLabel on DriverOrderHistoryDateFilter {
  String get label => switch (this) {
        DriverOrderHistoryDateFilter.all => 'All dates',
        DriverOrderHistoryDateFilter.today => 'Today',
        DriverOrderHistoryDateFilter.last7Days => 'Last 7 days',
        DriverOrderHistoryDateFilter.last30Days => 'Last 30 days',
      };
}

enum DriverOrderHistoryGroup { active, delivered, cancelled }

class DriverOrderHistoryItem {
  final String orderNumber;
  final String pickupBranch;
  final String destinationArea;
  final DriverDeliveryState state;
  final DateTime occurredAt;
  final int bagCount;
  final double driverEarning;
  final String currencyCode;
  final String? note;

  const DriverOrderHistoryItem({
    required this.orderNumber,
    required this.pickupBranch,
    required this.destinationArea,
    required this.state,
    required this.occurredAt,
    required this.bagCount,
    required this.driverEarning,
    required this.currencyCode,
    this.note,
  });

  DriverOrderHistoryGroup get group {
    if (state == DriverDeliveryState.delivered) {
      return DriverOrderHistoryGroup.delivered;
    }
    if (state == DriverDeliveryState.cancelled ||
        state == DriverDeliveryState.failedDelivery ||
        state == DriverDeliveryState.returnedToBranch) {
      return DriverOrderHistoryGroup.cancelled;
    }
    return DriverOrderHistoryGroup.active;
  }
}

class DriverOrderHistorySnapshot {
  final List<DriverOrderHistoryItem> items;
  final DateTime updatedAt;

  const DriverOrderHistorySnapshot({
    required this.items,
    required this.updatedAt,
  });

  List<String> get branches {
    final values = items.map((item) => item.pickupBranch).toSet().toList()
      ..sort();
    return List<String>.unmodifiable(values);
  }
}

class DriverOrderHistoryLoadResult {
  final DriverOrderHistorySnapshot? snapshot;
  final String? errorMessage;

  const DriverOrderHistoryLoadResult._({this.snapshot, this.errorMessage});

  const DriverOrderHistoryLoadResult.success(DriverOrderHistorySnapshot value)
      : this._(snapshot: value);

  const DriverOrderHistoryLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}
