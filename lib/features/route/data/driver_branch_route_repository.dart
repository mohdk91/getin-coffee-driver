import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../home/domain/driver_home_models.dart';
import '../../location/domain/driver_location_models.dart';
import '../domain/driver_branch_route_models.dart';

abstract interface class DriverBranchRouteRepository {
  DriverBranchRouteDataSource get source;

  Future<DriverBranchRouteLoadResult> load({
    required DriverActiveDeliverySummary delivery,
  });

  Future<String?> arriveAtBranch({
    required DriverActiveDeliverySummary delivery,
  });
}

class DriverBranchRouteRepositoryFactory {
  DriverBranchRouteRepositoryFactory._();

  static DriverBranchRouteRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverBranchRouteRepository();
    }
    return ApiDriverBranchRouteRepository(
        context ?? DriverApiContext.create(config));
  }
}

class ApiDriverBranchRouteRepository implements DriverBranchRouteRepository {
  final DriverApiContext context;

  const ApiDriverBranchRouteRepository(this.context);

  @override
  DriverBranchRouteDataSource get source => DriverBranchRouteDataSource.api;

  @override
  Future<DriverBranchRouteLoadResult> load({
    required DriverActiveDeliverySummary delivery,
  }) async {
    final orderId = delivery.apiOrderId;
    if (orderId == null) {
      return const DriverBranchRouteLoadResult.failure(
        'The active delivery is missing its Laravel order identifier. Refresh orders and try again.',
      );
    }
    try {
      await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$orderId/going-to-branch',
        authenticated: true,
        headers: <String, String>{
          'Idempotency-Key': 'driver-going-to-branch-$orderId',
        },
      );
      final order = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/orders/$orderId',
          authenticated: true,
        ),
      );
      final branch = order['branch'] is Map
          ? Map<String, dynamic>.from(order['branch'] as Map)
          : const <String, dynamic>{};
      final locationEnvelope = await context.apiClient.getJson(
        '/v1/driver/location',
        authenticated: true,
      );
      final rawLocation = locationEnvelope['data'];
      final location = rawLocation is Map
          ? Map<String, dynamic>.from(rawLocation)
          : const <String, dynamic>{};
      final branchLat = (branch['latitude'] as num?)?.toDouble();
      final branchLng = (branch['longitude'] as num?)?.toDouble();
      final driverLat = (location['latitude'] as num?)?.toDouble();
      final driverLng = (location['longitude'] as num?)?.toDouble();
      if (branchLat == null ||
          branchLng == null ||
          driverLat == null ||
          driverLng == null) {
        return const DriverBranchRouteLoadResult.failure(
          'Getin does not yet have enough branch/GPS coordinates to open navigation.',
        );
      }
      return DriverBranchRouteLoadResult.success(
        DriverBranchRouteInfo(
          apiOrderId: orderId,
          orderNumber:
              order['order_number']?.toString() ?? delivery.orderNumber,
          branchName: branch['name']?.toString() ?? delivery.pickupBranch,
          branchImageAsset: '',
          branchAddress: branch['address']?.toString() ?? '',
          branchPhoneLabel:
              branch['phone']?.toString() ?? 'Branch contact unavailable',
          branchCoordinates:
              DriverCoordinates(latitude: branchLat, longitude: branchLng),
          driverCoordinates:
              DriverCoordinates(latitude: driverLat, longitude: driverLng),
          etaMinutes: delivery.etaMinutes,
          distanceKm: 0,
          pickupInstructions: const <String>[
            'Use the designated driver pickup area when available.',
            'Do not confirm receipt until branch verification succeeds.',
          ],
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverBranchRouteLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverBranchRouteLoadResult.failure(error.message);
    }
  }

  @override
  Future<String?> arriveAtBranch({
    required DriverActiveDeliverySummary delivery,
  }) async {
    final orderId = delivery.apiOrderId;
    if (orderId == null) {
      return 'The active delivery is missing its Laravel order identifier.';
    }
    try {
      await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$orderId/arrived-at-branch',
        authenticated: true,
        headers: <String, String>{
          'Idempotency-Key': 'driver-arrived-at-branch-$orderId',
        },
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}

class DemoDriverBranchRouteRepository implements DriverBranchRouteRepository {
  const DemoDriverBranchRouteRepository();

  @override
  DriverBranchRouteDataSource get source => DriverBranchRouteDataSource.demo;

  @override
  Future<DriverBranchRouteLoadResult> load({
    required DriverActiveDeliverySummary delivery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return DriverBranchRouteLoadResult.success(
      DriverBranchRouteInfo(
        apiOrderId: delivery.apiOrderId,
        orderNumber: delivery.orderNumber,
        branchName: delivery.pickupBranch,
        branchImageAsset: 'assets/images/branches/getin_stanley.png',
        branchAddress: 'Alexandria, Egypt',
        branchPhoneLabel: 'Branch number supplied by operations',
        branchCoordinates:
            const DriverCoordinates(latitude: 31.2397, longitude: 29.9489),
        driverCoordinates:
            const DriverCoordinates(latitude: 31.24580, longitude: 29.96680),
        etaMinutes: delivery.etaMinutes,
        distanceKm: 2.1,
        pickupInstructions: const <String>[
          'Keep the order number ready for branch staff.',
          'Do not mark the order as received until branch verification is completed.',
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<String?> arriveAtBranch({
    required DriverActiveDeliverySummary delivery,
  }) async =>
      null;
}

class UnavailableDriverBranchRouteRepository
    implements DriverBranchRouteRepository {
  const UnavailableDriverBranchRouteRepository();

  @override
  DriverBranchRouteDataSource get source => DriverBranchRouteDataSource.api;

  @override
  Future<DriverBranchRouteLoadResult> load({
    required DriverActiveDeliverySummary delivery,
  }) async {
    return const DriverBranchRouteLoadResult.failure(
      'Branch route data is not connected to the Laravel API yet.',
    );
  }

  @override
  Future<String?> arriveAtBranch({
    required DriverActiveDeliverySummary delivery,
  }) async =>
      'Arrival could not be confirmed with Getin.';
}
