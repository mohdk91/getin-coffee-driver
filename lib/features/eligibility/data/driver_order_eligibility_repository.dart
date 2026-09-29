import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
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

  static DriverOrderEligibilityRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverOrderEligibilityRepository()
        : const UnavailableDriverOrderEligibilityRepository();
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
