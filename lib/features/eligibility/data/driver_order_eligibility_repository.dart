import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../home/domain/driver_home_models.dart';
import '../../location/domain/driver_location_models.dart';
import '../domain/driver_order_eligibility_engine.dart';
import '../domain/driver_order_eligibility_models.dart';

enum DriverOrderEligibilityDataSource { demo, api }

class DriverOrderEligibilityLoadResult {
  final DriverOrderEligibilitySnapshot? snapshot;
  final String? errorMessage;

  const DriverOrderEligibilityLoadResult._({this.snapshot, this.errorMessage});

  const DriverOrderEligibilityLoadResult.success(
    DriverOrderEligibilitySnapshot value,
  ) : this._(snapshot: value);

  const DriverOrderEligibilityLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}

abstract interface class DriverOrderEligibilityRepository {
  DriverOrderEligibilityDataSource get source;

  Future<DriverOrderEligibilityLoadResult> evaluate({
    required DriverAvailabilityState availability,
    required int activeOrderCount,
    required bool driverApproved,
  });
}

class DriverOrderEligibilityRepositoryFactory {
  DriverOrderEligibilityRepositoryFactory._();

  static DriverOrderEligibilityRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const DemoDriverOrderEligibilityRepository();
    }
    return ApiDriverOrderEligibilityRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverOrderEligibilityRepository
    implements DriverOrderEligibilityRepository {
  final DriverApiContext context;

  const ApiDriverOrderEligibilityRepository(this.context);

  @override
  DriverOrderEligibilityDataSource get source =>
      DriverOrderEligibilityDataSource.api;

  @override
  Future<DriverOrderEligibilityLoadResult> evaluate({
    required DriverAvailabilityState availability,
    required int activeOrderCount,
    required bool driverApproved,
  }) async {
    try {
      final data = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/eligibility',
          authenticated: true,
        ),
      );
      final details = data['details'] is Map
          ? Map<String, dynamic>.from(data['details'] as Map)
          : const <String, dynamic>{};
      final checks = data['checks'] is Map
          ? Map<String, dynamic>.from(data['checks'] as Map)
          : const <String, dynamic>{};
      final now = DateTime.now();
      final gpsAge = (details['gps_age_seconds'] as num?)?.toInt();
      final gpsAccuracy = (details['gps_accuracy_meters'] as num?)?.toDouble();

      final contextSnapshot = DriverEligibilityContext(
        driverApproved: checks['approved'] == true,
        availability: checks['online'] == true
            ? DriverAvailabilityState.online
            : availability,
        gps: gpsAccuracy == null
            ? null
            : DriverGpsFix(
                coordinates: const DriverCoordinates(latitude: 0, longitude: 0),
                accuracyMeters: gpsAccuracy,
                capturedAt: gpsAge == null
                    ? now
                    : now.subtract(Duration(seconds: gpsAge)),
                state: checks['gps_fresh'] == true &&
                        checks['gps_accurate'] == true
                    ? DriverGpsState.ready
                    : DriverGpsState.stale,
              ),
        region: details['matched_region_id']?.toString() ?? '',
        zone: '',
        allowedBranches: (details['assigned_branch_ids'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false),
        deliveryRadiusKm:
            (details['distance_to_branch_km'] as num?)?.toDouble() ?? 0,
        vehicleType: checks['vehicle'] == true ? 'eligible' : 'unavailable',
        activeOrderCount:
            (details['active_orders'] as num?)?.toInt() ?? activeOrderCount,
        maxActiveOrders: (details['max_active_orders'] as num?)?.toInt() ?? 1,
        evaluatedAt: now,
      );

      final eligible = data['eligible'] == true;
      final decisions = <DriverOrderEligibilityDecision>[];
      if (eligible) {
        final ordersEnvelope = await context.apiClient.getJson(
          '/v1/driver/orders/available',
          authenticated: true,
          query: const <String, Object?>{'per_page': 50},
        );
        for (final raw in DriverApiContext.dataList(ordersEnvelope)) {
          if (raw is! Map) continue;
          final order = Map<String, dynamic>.from(raw);
          final branch = order['branch'] is Map
              ? Map<String, dynamic>.from(order['branch'] as Map)
              : const <String, dynamic>{};
          final destination = order['destination'] is Map
              ? Map<String, dynamic>.from(order['destination'] as Map)
              : const <String, dynamic>{};
          final candidate = DriverOrderCandidate(
            apiOrderId: (order['id'] as num?)?.toInt(),
            orderNumber: order['order_number']?.toString() ?? '',
            pickupBranch: branch['name']?.toString() ?? 'Branch',
            region: contextSnapshot.region,
            zone: contextSnapshot.zone,
            destinationArea: destination['area']?.toString() ??
                destination['city']?.toString() ??
                'Delivery area',
            distanceToBranchKm: 0,
            deliveryDistanceKm: 0,
            estimatedDurationMinutes: 0,
            bagCount: 1,
            estimatedDriverEarning: 0,
            currencyCode: order['currency']?.toString() ?? 'EGP',
            allowedVehicleTypes: const <String>[],
            isAvailable: true,
          );
          decisions.add(
            DriverOrderEligibilityDecision(
              order: candidate,
              checks: const <DriverEligibilityRuleCheck>[
                DriverEligibilityRuleCheck(
                  rule: DriverOrderEligibilityRule.driverApproved,
                  passed: true,
                  detail: 'Laravel eligibility accepted this order.',
                ),
                DriverEligibilityRuleCheck(
                  rule: DriverOrderEligibilityRule.orderAvailable,
                  passed: true,
                  detail: 'Order remains in the server available pool.',
                ),
              ],
            ),
          );
        }
      }

      final existingOrderIds = decisions
          .map((decision) => decision.order.apiOrderId)
          .whereType<int>()
          .toSet();
      final offersEnvelope = await context.apiClient.getJson(
        '/v1/driver/order-offers',
        authenticated: true,
      );
      for (final raw in DriverApiContext.dataList(offersEnvelope)) {
        if (raw is! Map) continue;
        final offer = Map<String, dynamic>.from(raw);
        final status = offer['status']?.toString().toLowerCase() ?? '';
        if (status == 'rejected' ||
            status == 'expired' ||
            status == 'accepted') {
          continue;
        }
        final orderRaw = offer['order'];
        if (orderRaw is! Map) continue;
        final order = Map<String, dynamic>.from(orderRaw);
        final orderId = (order['id'] as num?)?.toInt();
        if (orderId != null && existingOrderIds.contains(orderId)) continue;
        final branch = order['branch'] is Map
            ? Map<String, dynamic>.from(order['branch'] as Map)
            : const <String, dynamic>{};
        final destination = order['destination'] is Map
            ? Map<String, dynamic>.from(order['destination'] as Map)
            : const <String, dynamic>{};
        final candidate = DriverOrderCandidate(
          apiOrderId: orderId,
          apiOfferId: (offer['id'] as num?)?.toInt(),
          orderNumber: order['order_number']?.toString() ?? '',
          pickupBranch: branch['name']?.toString() ?? 'Branch',
          region: contextSnapshot.region,
          zone: contextSnapshot.zone,
          destinationArea: destination['area']?.toString() ??
              destination['city']?.toString() ??
              'Delivery area',
          distanceToBranchKm: 0,
          deliveryDistanceKm: 0,
          estimatedDurationMinutes: 0,
          bagCount: 1,
          estimatedDriverEarning: 0,
          currencyCode: order['currency']?.toString() ?? 'EGP',
          allowedVehicleTypes: const <String>[],
          isAvailable: true,
        );
        decisions.add(
          DriverOrderEligibilityDecision(
            order: candidate,
            checks: const <DriverEligibilityRuleCheck>[
              DriverEligibilityRuleCheck(
                rule: DriverOrderEligibilityRule.driverApproved,
                passed: true,
                detail: 'Laravel offered this order directly to the driver.',
              ),
              DriverEligibilityRuleCheck(
                rule: DriverOrderEligibilityRule.orderAvailable,
                passed: true,
                detail: 'Offer is active on the server.',
              ),
            ],
          ),
        );
      }

      return DriverOrderEligibilityLoadResult.success(
        DriverOrderEligibilitySnapshot(
          context: contextSnapshot,
          decisions: decisions,
        ),
      );
    } on ApiException catch (error) {
      return DriverOrderEligibilityLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverOrderEligibilityLoadResult.failure(error.message);
    }
  }
}

class DemoDriverOrderEligibilityRepository
    implements DriverOrderEligibilityRepository {
  final DriverOrderEligibilityEngine engine;

  const DemoDriverOrderEligibilityRepository({
    this.engine = const DriverOrderEligibilityEngine(),
  });

  @override
  DriverOrderEligibilityDataSource get source =>
      DriverOrderEligibilityDataSource.demo;

  @override
  Future<DriverOrderEligibilityLoadResult> evaluate({
    required DriverAvailabilityState availability,
    required int activeOrderCount,
    required bool driverApproved,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));

    final now = DateTime.now();
    final context = DriverEligibilityContext(
      driverApproved: driverApproved,
      availability: availability,
      gps: DriverGpsFix(
        coordinates: const DriverCoordinates(
          latitude: 31.24580,
          longitude: 29.96680,
        ),
        accuracyMeters: 12,
        capturedAt: now,
        state: DriverGpsState.ready,
      ),
      region: 'Stanley / San Stefano',
      zone: 'East Alexandria',
      allowedBranches: const ['Stanley', 'Gleem'],
      deliveryRadiusKm: 8,
      vehicleType: 'Motorbike',
      activeOrderCount: activeOrderCount,
      maxActiveOrders: 1,
      evaluatedAt: now,
    );

    const candidates = <DriverOrderCandidate>[
      DriverOrderCandidate(
        orderNumber: 'GD-3101',
        pickupBranch: 'Stanley',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        destinationArea: 'San Stefano',
        distanceToBranchKm: 2.1,
        deliveryDistanceKm: 4.6,
        estimatedDurationMinutes: 19,
        bagCount: 2,
        estimatedDriverEarning: 72,
        allowedVehicleTypes: ['Motorbike', 'Car'],
        isAvailable: true,
      ),
      DriverOrderCandidate(
        orderNumber: 'GD-3102',
        pickupBranch: 'Gleem',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        destinationArea: 'Roushdy',
        distanceToBranchKm: 3.4,
        deliveryDistanceKm: 6.8,
        estimatedDurationMinutes: 27,
        bagCount: 1,
        estimatedDriverEarning: 88,
        allowedVehicleTypes: ['Motorbike'],
        isAvailable: true,
      ),
      DriverOrderCandidate(
        orderNumber: 'GD-3103',
        pickupBranch: 'Smouha',
        region: 'Smouha',
        zone: 'Central Alexandria',
        destinationArea: 'Smouha',
        distanceToBranchKm: 5.2,
        deliveryDistanceKm: 5.4,
        estimatedDurationMinutes: 24,
        bagCount: 2,
        estimatedDriverEarning: 79,
        allowedVehicleTypes: ['Motorbike', 'Car'],
        isAvailable: true,
      ),
      DriverOrderCandidate(
        orderNumber: 'GD-3104',
        pickupBranch: 'Stanley',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        destinationArea: 'Sidi Gaber',
        distanceToBranchKm: 2.7,
        deliveryDistanceKm: 11.9,
        estimatedDurationMinutes: 36,
        bagCount: 3,
        estimatedDriverEarning: 112,
        allowedVehicleTypes: ['Motorbike', 'Car'],
        isAvailable: true,
      ),
      DriverOrderCandidate(
        orderNumber: 'GD-3105',
        pickupBranch: 'Gleem',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        destinationArea: 'Glim',
        distanceToBranchKm: 3.1,
        deliveryDistanceKm: 5.1,
        estimatedDurationMinutes: 22,
        bagCount: 4,
        estimatedDriverEarning: 91,
        allowedVehicleTypes: ['Car'],
        isAvailable: true,
      ),
      DriverOrderCandidate(
        orderNumber: 'GD-3106',
        pickupBranch: 'Stanley',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        destinationArea: 'Stanley',
        distanceToBranchKm: 2.4,
        deliveryDistanceKm: 4.0,
        estimatedDurationMinutes: 17,
        bagCount: 1,
        estimatedDriverEarning: 67,
        allowedVehicleTypes: ['Motorbike'],
        isAvailable: false,
      ),
    ];

    return DriverOrderEligibilityLoadResult.success(
      engine.evaluate(context: context, candidates: candidates),
    );
  }
}

class UnavailableDriverOrderEligibilityRepository
    implements DriverOrderEligibilityRepository {
  const UnavailableDriverOrderEligibilityRepository();

  @override
  DriverOrderEligibilityDataSource get source =>
      DriverOrderEligibilityDataSource.api;

  @override
  Future<DriverOrderEligibilityLoadResult> evaluate({
    required DriverAvailabilityState availability,
    required int activeOrderCount,
    required bool driverApproved,
  }) async {
    return const DriverOrderEligibilityLoadResult.failure(
      'Smart order eligibility is not connected to the Laravel API yet. No orders are exposed without a server eligibility decision.',
    );
  }
}
