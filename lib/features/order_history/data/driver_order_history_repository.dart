import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../active_delivery/domain/driver_delivery_state_machine.dart';
import '../domain/driver_order_history_models.dart';

abstract interface class DriverOrderHistoryRepository {
  DriverOrderHistoryDataSource get source;
  Future<DriverOrderHistoryLoadResult> load();
}

class DriverOrderHistoryRepositoryFactory {
  DriverOrderHistoryRepositoryFactory._();

  static DriverOrderHistoryRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverOrderHistoryRepository()
        : const UnavailableDriverOrderHistoryRepository();
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
