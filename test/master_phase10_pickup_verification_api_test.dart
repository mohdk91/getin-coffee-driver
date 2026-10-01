import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';

void main() {
  test('Task 112 pickup route retains backend order identity', () {
    final route = DriverBranchRouteInfo(
      apiOrderId: 91,
      orderNumber: 'GD-91',
      branchName: 'Stanley',
      branchImageAsset: '',
      branchAddress: 'Alexandria',
      branchPhoneLabel: '',
      branchCoordinates: const DriverCoordinates(latitude: 1, longitude: 2),
      driverCoordinates: const DriverCoordinates(latitude: 1, longitude: 2),
      etaMinutes: 1,
      distanceKm: 1,
      pickupInstructions: const <String>[],
      updatedAt: DateTime(2026),
    );
    expect(route.apiOrderId, 91);
  });
}
