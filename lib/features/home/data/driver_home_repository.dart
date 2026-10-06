import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/uat/driver_uat_completed_delivery_store.dart';
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
    if (config.uatDemoEnabled) {
      return const UatDriverHomeRepository();
    }
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
      final now = DateTime.now();
      final today = _dateOnly(now);

      final availabilityData = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/availability',
          authenticated: true,
        ),
      );

      final runtimeData = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/runtime',
          authenticated: true,
        ),
      );

      final ordersEnvelope = await context.apiClient.getJson(
        '/v1/driver/orders/available',
        authenticated: true,
        query: const <String, Object?>{'per_page': 1},
      );
      final meta = ordersEnvelope['meta'];
      final publicAvailableOrders = meta is Map
          ? ((meta['total'] as num?)?.toInt() ?? 0)
          : DriverApiContext.dataList(ordersEnvelope).length;
      final offersEnvelope = await context.apiClient.getJson(
        '/v1/driver/order-offers',
        authenticated: true,
      );
      final activeDirectOffers = DriverApiContext.dataList(offersEnvelope)
          .whereType<Map>()
          .where(
              (offer) => offer['status']?.toString().toLowerCase() == 'offered')
          .length;
      final availableOrders = publicAvailableOrders + activeDirectOffers;

      final earningsData = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/earnings/summary',
          authenticated: true,
          query: <String, Object?>{
            'date_from': today,
            'date_to': today,
          },
        ),
      );
      final earningsRows = (earningsData['currencies'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      final primaryEarnings =
          earningsRows.isEmpty ? const <String, dynamic>{} : earningsRows.first;

      final ratingsData = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/ratings/summary',
          authenticated: true,
        ),
      );
      final unreadData = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/notifications/unread-count',
          authenticated: true,
        ),
      );

      final locationEnvelope = await context.apiClient.getJson(
        '/v1/driver/location',
        authenticated: true,
      );
      final rawLocation = locationEnvelope['data'];
      final locationData = rawLocation is Map
          ? Map<String, dynamic>.from(rawLocation)
          : const <String, dynamic>{};
      final locationPolicy = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/location/policy',
          authenticated: true,
        ),
      );

      return DriverHomeLoadResult.success(
        DriverHomeSnapshot(
          availability: _availability(availabilityData['status']?.toString()),
          activeDelivery: _activeDelivery(runtimeData['active_delivery']),
          availableOrders: availableOrders,
          completedToday: (primaryEarnings['records'] as num?)?.toInt() ?? 0,
          earningsToday: double.tryParse(
                  primaryEarnings['final_earning']?.toString() ?? '') ??
              0,
          currencyCode: primaryEarnings['currency']?.toString() ?? 'EGP',
          rating: (ratingsData['average_rating'] as num?)?.toDouble() ?? 0,
          ratingCount: (ratingsData['total_ratings'] as num?)?.toInt() ?? 0,
          unreadNotifications:
              (unreadData['unread_count'] as num?)?.toInt() ?? 0,
          gpsState: _gpsState(locationData, locationPolicy, now),
          internetConnected: true,
          updatedAt: now,
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

  static DriverActiveDeliverySummary? _activeDelivery(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const FormatException('Driver runtime active delivery is invalid.');
    }
    final order = Map<String, dynamic>.from(raw);
    final id = (order['id'] as num?)?.toInt();
    final number = order['order_number']?.toString();
    final state = order['delivery_state']?.toString();
    if (id == null || number == null || state == null) {
      throw const FormatException('Driver runtime delivery is incomplete.');
    }
    final branch = order['branch'] is Map
        ? Map<String, dynamic>.from(order['branch'] as Map)
        : const <String, dynamic>{};
    final delivery = order['delivery'] is Map
        ? Map<String, dynamic>.from(order['delivery'] as Map)
        : const <String, dynamic>{};
    return DriverActiveDeliverySummary(
      apiOrderId: id,
      orderNumber: number,
      status: state,
      pickupBranch: branch['name']?.toString() ?? 'Assigned branch',
      destinationArea: delivery['area']?.toString() ??
          delivery['city']?.toString() ??
          'Delivery destination',
      etaMinutes: 0,
    );
  }

  static DriverGpsState _gpsState(
    Map<String, dynamic> location,
    Map<String, dynamic> policy,
    DateTime now,
  ) {
    if (location.isEmpty) return DriverGpsState.stale;
    final recordedAt =
        DateTime.tryParse(location['timestamp']?.toString() ?? '')?.toLocal();
    final accuracy = (location['accuracy'] as num?)?.toDouble();
    final quality = policy['quality'] is Map
        ? Map<String, dynamic>.from(policy['quality'] as Map)
        : const <String, dynamic>{};
    final maxStale = (quality['max_stale_seconds'] as num?)?.toInt() ?? 180;
    final maxAccuracy =
        (quality['max_accuracy_meters'] as num?)?.toDouble() ?? 100;
    if (recordedAt == null || now.difference(recordedAt).inSeconds > maxStale) {
      return DriverGpsState.stale;
    }
    if (accuracy == null || accuracy > maxAccuracy) {
      return DriverGpsState.inaccurate;
    }
    return DriverGpsState.ready;
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class UatDriverHomeRepository implements DriverHomeRepository {
  final DriverUatCompletedDeliveryStore completedStore;

  const UatDriverHomeRepository({
    this.completedStore =
        const SharedPreferencesDriverUatCompletedDeliveryStore(),
  });

  @override
  DriverHomeDataSource get source => DriverHomeDataSource.demo;

  @override
  Future<DriverHomeLoadResult> loadDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final now = DateTime.now();
    final records = await completedStore.load();
    final today =
        records.where((record) => _sameLocalDay(record.completedAt, now));
    final completedToday = today.length;
    final earningsToday = today.fold<double>(
      0,
      (total, record) => total + record.driverEarning,
    );

    return DriverHomeLoadResult.success(
      DriverHomeSnapshot(
        availability: DriverAvailabilityState.online,
        activeDelivery: null,
        availableOrders: 0,
        completedToday: completedToday,
        earningsToday: earningsToday,
        currencyCode: 'EGP',
        rating: 4.9,
        ratingCount: 126,
        unreadNotifications: 0,
        gpsState: DriverGpsState.ready,
        internetConnected: true,
        updatedAt: now,
      ),
    );
  }

  bool _sameLocalDay(DateTime value, DateTime now) {
    final local = value.toLocal();
    final localNow = now.toLocal();
    return local.year == localNow.year &&
        local.month == localNow.month &&
        local.day == localNow.day;
  }
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
