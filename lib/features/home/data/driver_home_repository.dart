import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_home_models.dart';

enum DriverHomeDataSource { demo, api }

class DriverHomeLoadResult {
  final DriverHomeSnapshot? snapshot;
  final String? errorMessage;

  const DriverHomeLoadResult._({this.snapshot, this.errorMessage});

  const DriverHomeLoadResult.success(DriverHomeSnapshot snapshot)
      : this._(snapshot: snapshot);

  const DriverHomeLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}

abstract interface class DriverHomeRepository {
  DriverHomeDataSource get source;

  Future<DriverHomeLoadResult> loadDashboard();
}

class DriverHomeRepositoryFactory {
  DriverHomeRepositoryFactory._();

  static DriverHomeRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const DemoDriverHomeRepository();
    }
    return ApiDriverHomeRepository(context ?? DriverApiContext.create(config));
  }
}

class ApiDriverHomeRepository implements DriverHomeRepository {
  final DriverApiContext context;

  const ApiDriverHomeRepository(this.context);

  @override
  DriverHomeDataSource get source => DriverHomeDataSource.api;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    try {
      final availabilityEnvelope = await context.apiClient.getJson(
        '/v1/driver/availability',
        authenticated: true,
      );
      final availabilityData = DriverApiContext.dataMap(availabilityEnvelope);

      final ordersEnvelope = await context.apiClient.getJson(
        '/v1/driver/orders/available',
        authenticated: true,
        query: const <String, Object?>{'per_page': 1},
      );
      final meta = ordersEnvelope['meta'];
      final availableOrders = meta is Map
          ? ((meta['total'] as num?)?.toInt() ?? 0)
          : DriverApiContext.dataList(ordersEnvelope).length;

      return DriverHomeLoadResult.success(
        DriverHomeSnapshot(
          availability: _availability(availabilityData['status']?.toString()),
          activeDelivery: null,
          availableOrders: availableOrders,
          completedToday: 0,
          earningsToday: 0,
          currencyCode: 'EGP',
          rating: 0,
          ratingCount: 0,
          unreadNotifications: 0,
          gpsState: DriverGpsState.ready,
          internetConnected: true,
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverHomeLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverHomeLoadResult.failure(error.message);
    }
  }

  static DriverAvailabilityState _availability(String? value) =>
      switch (value) {
        'online' => DriverAvailabilityState.online,
        'on_break' => DriverAvailabilityState.onBreak,
        _ => DriverAvailabilityState.offline,
      };
}

class DemoDriverHomeRepository implements DriverHomeRepository {
  const DemoDriverHomeRepository();

  @override
  DriverHomeDataSource get source => DriverHomeDataSource.demo;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    return DriverHomeLoadResult.success(
      DriverHomeSnapshot(
        availability: DriverAvailabilityState.online,
        activeDelivery: const DriverActiveDeliverySummary(
          orderNumber: 'GD-2481',
          status: 'Going to branch',
          pickupBranch: 'Stanley',
          destinationArea: 'San Stefano',
          etaMinutes: 8,
        ),
        availableOrders: 4,
        completedToday: 7,
        earningsToday: 485.50,
        currencyCode: 'EGP',
        rating: 4.9,
        ratingCount: 126,
        unreadNotifications: 3,
        gpsState: DriverGpsState.ready,
        internetConnected: true,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
