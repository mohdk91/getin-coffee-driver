import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../home/domain/driver_home_models.dart';
import '../../location/domain/driver_location_models.dart';
import '../domain/driver_branch_route_models.dart';

abstract interface class DriverBranchRouteRepository {
  DriverBranchRouteDataSource get source;

  Future<DriverBranchRouteLoadResult> load({
    required DriverActiveDeliverySummary delivery,
  });
}

class DriverBranchRouteRepositoryFactory {
  DriverBranchRouteRepositoryFactory._();

  static DriverBranchRouteRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverBranchRouteRepository()
        : const UnavailableDriverBranchRouteRepository();
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

    final branch = _branchFor(delivery.pickupBranch);
    final distance = switch (delivery.pickupBranch.toLowerCase()) {
      'stanley' => 2.1,
      'gleem' => 3.4,
      'smouha' => 5.2,
      _ => 2.4,
    };

    return DriverBranchRouteLoadResult.success(
      DriverBranchRouteInfo(
        orderNumber: delivery.orderNumber,
        branchName: delivery.pickupBranch,
        branchImageAsset: branch.imageAsset,
        branchAddress: branch.address,
        branchPhoneLabel: 'Branch number supplied by operations',
        branchCoordinates: branch.coordinates,
        driverCoordinates: const DriverCoordinates(
          latitude: 31.24580,
          longitude: 29.96680,
        ),
        etaMinutes: delivery.etaMinutes,
        distanceKm: distance,
        pickupInstructions: const [
          'Use the designated driver pickup area when available.',
          'Keep the order number ready for branch staff.',
          'Confirm the bag count and handling notes before leaving.',
          'Do not mark the order as received until branch verification is completed.',
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  _DemoBranchDefinition _branchFor(String branchName) {
    return switch (branchName.toLowerCase()) {
      'stanley' => const _DemoBranchDefinition(
          imageAsset: 'assets/images/branches/getin_stanley.png',
          address: 'Stanley, Alexandria, Egypt',
          coordinates: DriverCoordinates(
            latitude: 31.2397,
            longitude: 29.9489,
          ),
        ),
      'gleem' => const _DemoBranchDefinition(
          imageAsset: 'assets/images/branches/getin_san_stefano.png',
          address: 'Gleem, Alexandria, Egypt',
          coordinates: DriverCoordinates(
            latitude: 31.2454,
            longitude: 29.9659,
          ),
        ),
      'smouha' => const _DemoBranchDefinition(
          imageAsset: 'assets/images/branches/getin_smouha.png',
          address: 'Smouha, Alexandria, Egypt',
          coordinates: DriverCoordinates(
            latitude: 31.2156,
            longitude: 29.9553,
          ),
        ),
      _ => const _DemoBranchDefinition(
          imageAsset: 'assets/images/branches/getin_stanley.png',
          address: 'Alexandria, Egypt',
          coordinates: DriverCoordinates(
            latitude: 31.2397,
            longitude: 29.9489,
          ),
        ),
    };
  }
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
      'Branch route data is not connected to the Laravel API yet. Getin will not invent a pickup address, phone number, or route in production.',
    );
  }
}

class _DemoBranchDefinition {
  final String imageAsset;
  final String address;
  final DriverCoordinates coordinates;

  const _DemoBranchDefinition({
    required this.imageAsset,
    required this.address,
    required this.coordinates,
  });
}
