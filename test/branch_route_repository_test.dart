import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/route/data/driver_branch_route_repository.dart';
import 'package:getin_driver/features/route/domain/driver_branch_route_models.dart';

void main() {
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-3101',
    status: 'Accepted',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  test('Task 12 demo route contains branch operational data', () async {
    const repository = DemoDriverBranchRouteRepository();

    final result = await repository.load(delivery: delivery);

    expect(result.isSuccess, isTrue);
    expect(result.route, isNotNull);
    expect(result.route!.orderNumber, 'GD-3101');
    expect(result.route!.branchName, 'Stanley');
    expect(result.route!.branchAddress, contains('Alexandria'));
    expect(result.route!.etaMinutes, 19);
    expect(result.route!.distanceKm, greaterThan(0));
    expect(result.route!.pickupInstructions, isNotEmpty);
    expect(repository.source, DriverBranchRouteDataSource.demo);
  });

  test('Task 12 production repository refuses invented route data', () async {
    const repository = UnavailableDriverBranchRouteRepository();

    final result = await repository.load(delivery: delivery);

    expect(result.isSuccess, isFalse);
    expect(result.route, isNull);
    expect(result.errorMessage, contains('not connected'));
    expect(repository.source, DriverBranchRouteDataSource.api);
  });
}
