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
