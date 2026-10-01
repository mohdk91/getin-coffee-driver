import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../active_delivery/domain/driver_delivery_state_machine.dart';
import '../domain/driver_order_history_models.dart';

abstract interface class DriverOrderHistoryRepository {
  DriverOrderHistoryDataSource get source;
  Future<DriverOrderHistoryLoadResult> load();
}

class DriverOrderHistoryRepositoryFactory {
  DriverOrderHistoryRepositoryFactory._();

  static DriverOrderHistoryRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverOrderHistoryRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.environment == AppEnvironment.development
        ? const DemoDriverOrderHistoryRepository()
        : const UnavailableDriverOrderHistoryRepository();
  }
}

class ApiDriverOrderHistoryRepository implements DriverOrderHistoryRepository {
  final DriverApiContext context;
  const ApiDriverOrderHistoryRepository(this.context);

  @override
  DriverOrderHistoryDataSource get source => DriverOrderHistoryDataSource.api;

  @override
  Future<DriverOrderHistoryLoadResult> load() async {
    try {
      final envelope = await context.apiClient.getJson(
        '/v1/driver/history',
        query: const <String, Object?>{'per_page': 50},
        authenticated: true,
      );
      final items = DriverApiContext.nestedItems(envelope)
          .whereType<Map>()
          .map((raw) => _item(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
      return DriverOrderHistoryLoadResult.success(
        DriverOrderHistorySnapshot(items: items, updatedAt: DateTime.now()),
      );
    } on ApiException catch (error) {
      return DriverOrderHistoryLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverOrderHistoryLoadResult.failure(error.message);
    }
  }

  DriverOrderHistoryItem _item(Map<String, dynamic> raw) {
    final branch = raw['branch'] is Map
        ? Map<String, dynamic>.from(raw['branch'] as Map)
        : const <String, dynamic>{};
    final destination = raw['destination'] is Map
        ? Map<String, dynamic>.from(raw['destination'] as Map)
        : const <String, dynamic>{};
    final earning = raw['earning'] is Map
        ? Map<String, dynamic>.from(raw['earning'] as Map)
        : const <String, dynamic>{};
    final stateName = raw['delivery_state']?.toString() ?? 'accepted';

    return DriverOrderHistoryItem(
      orderNumber: raw['order_number']?.toString() ?? '',
      pickupBranch: branch['name']?.toString() ?? 'Branch',
      destinationArea: destination['area']?.toString() ??
          destination['city']?.toString() ??
          'Destination',
      state: driverDeliveryStateFromStatus(stateName),
      occurredAt: DateTime.tryParse(raw['occurred_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      bagCount: (raw['bag_count'] as num?)?.toInt() ?? 0,
      driverEarning: double.tryParse(earning['amount']?.toString() ?? '') ?? 0,
      currencyCode: earning['currency']?.toString() ?? 'EGP',
      note: raw['note']?.toString(),
    );
  }
}

class DemoDriverOrderHistoryRepository implements DriverOrderHistoryRepository {
  const DemoDriverOrderHistoryRepository();

  @override
  DriverOrderHistoryDataSource get source => DriverOrderHistoryDataSource.demo;

  @override
  Future<DriverOrderHistoryLoadResult> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final now = DateTime.now();
    return DriverOrderHistoryLoadResult.success(
      DriverOrderHistorySnapshot(
        updatedAt: now,
        items: [
          DriverOrderHistoryItem(
            orderNumber: 'GD-2476',
            pickupBranch: 'Stanley',
            destinationArea: 'San Stefano',
            state: DriverDeliveryState.delivered,
            occurredAt: now.subtract(const Duration(hours: 3)),
            bagCount: 2,
            driverEarning: 72,
            currencyCode: 'EGP',
          ),
          DriverOrderHistoryItem(
            orderNumber: 'GD-2468',
            pickupBranch: 'Gleem',
            destinationArea: 'Roushdy',
            state: DriverDeliveryState.delivered,
            occurredAt: now.subtract(const Duration(days: 2, hours: 1)),
            bagCount: 1,
            driverEarning: 61,
            currencyCode: 'EGP',
          ),
          DriverOrderHistoryItem(
            orderNumber: 'GD-2451',
            pickupBranch: 'Stanley',
            destinationArea: 'Sporting',
            state: DriverDeliveryState.cancelled,
            occurredAt: now.subtract(const Duration(days: 5)),
            bagCount: 2,
            driverEarning: 0,
            currencyCode: 'EGP',
            note: 'Cancelled before pickup.',
          ),
          DriverOrderHistoryItem(
            orderNumber: 'GD-2419',
            pickupBranch: 'Gleem',
            destinationArea: 'Sidi Gaber',
            state: DriverDeliveryState.returnedToBranch,
            occurredAt: now.subtract(const Duration(days: 12)),
            bagCount: 1,
            driverEarning: 24,
            currencyCode: 'EGP',
            note: 'Returned to branch after delivery exception.',
          ),
          DriverOrderHistoryItem(
            orderNumber: 'GD-2397',
            pickupBranch: 'Stanley',
            destinationArea: 'Smouha',
            state: DriverDeliveryState.failedDelivery,
            occurredAt: now.subtract(const Duration(days: 22)),
            bagCount: 3,
            driverEarning: 18,
            currencyCode: 'EGP',
            note: 'Delivery exception recorded.',
          ),
        ],
      ),
    );
  }
}

class UnavailableDriverOrderHistoryRepository
    implements DriverOrderHistoryRepository {
  const UnavailableDriverOrderHistoryRepository();

  @override
  DriverOrderHistoryDataSource get source => DriverOrderHistoryDataSource.api;

  @override
  Future<DriverOrderHistoryLoadResult> load() async {
    return const DriverOrderHistoryLoadResult.failure(
      'Order history is not connected to the Laravel API yet. Getin will not invent delivered or cancelled orders in production.',
    );
  }
}
