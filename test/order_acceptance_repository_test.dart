import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/eligibility/domain/driver_order_eligibility_models.dart';
import 'package:getin_driver/features/orders/data/driver_order_acceptance_repository.dart';
import 'package:getin_driver/features/orders/domain/driver_order_acceptance_models.dart';

const _order = DriverOrderCandidate(
  orderNumber: 'GD-LOCK-1',
  pickupBranch: 'Stanley',
  region: 'Stanley / San Stefano',
  zone: 'East Alexandria',
  destinationArea: 'San Stefano',
  distanceToBranchKm: 2,
  deliveryDistanceKm: 4,
  estimatedDurationMinutes: 18,
  bagCount: 1,
  estimatedDriverEarning: 70,
  allowedVehicleTypes: ['Motorbike'],
  isAvailable: true,
);

void main() {
  test('Task 11 local atomic lock allows only one driver to acquire an order',
      () async {
    final store = DemoOrderLockStore();
    final firstRepository = DemoDriverOrderAcceptanceRepository(
      lockStore: store,
      responseDelay: Duration.zero,
      seedTakenOrder: false,
    );
    final secondRepository = DemoDriverOrderAcceptanceRepository(
      lockStore: store,
      responseDelay: Duration.zero,
      seedTakenOrder: false,
    );

    final results = await Future.wait([
      firstRepository.accept(order: _order, driverId: 'driver-a'),
      secondRepository.accept(order: _order, driverId: 'driver-b'),
    ]);

    expect(
      results.where((result) => result.isAccepted).length,
      1,
    );
    expect(
      results
          .where(
            (result) =>
                result.outcome == DriverOrderAcceptanceOutcome.alreadyTaken,
          )
          .length,
      1,
    );
    expect(store.ownerOf(_order.orderNumber), isNotNull);
  });

  test('same driver retry is idempotent in the local lock store', () async {
    final store = DemoOrderLockStore();
    final repository = DemoDriverOrderAcceptanceRepository(
      lockStore: store,
      responseDelay: Duration.zero,
      seedTakenOrder: false,
    );

    final first = await repository.accept(order: _order, driverId: 'driver-a');
    final second = await repository.accept(order: _order, driverId: 'driver-a');

    expect(first.isAccepted, isTrue);
    expect(second.isAccepted, isTrue);
    expect(second.lockToken, first.lockToken);
  });

  test('production acceptance repository never fakes a successful lock',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: '',
    );
    final repository = DriverOrderAcceptanceRepositoryFactory.create(config);

    final result = await repository.accept(
      order: _order,
      driverId: 'driver-a',
    );

    expect(result.outcome, DriverOrderAcceptanceOutcome.serverFailure);
    expect(result.isAccepted, isFalse);
    expect(result.canRetry, isTrue);
  });
}
