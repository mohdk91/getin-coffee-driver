import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../eligibility/domain/driver_order_eligibility_models.dart';
import '../domain/driver_order_acceptance_models.dart';

enum DriverOrderAcceptanceDataSource { demo, api }

abstract interface class DriverOrderAcceptanceRepository {
  DriverOrderAcceptanceDataSource get source;

  Future<DriverOrderAcceptanceResult> accept({
    required DriverOrderCandidate order,
    required String driverId,
  });
}

class DemoOrderLockRecord {
  final String driverId;
  final String lockToken;
  final DateTime lockedAt;

  const DemoOrderLockRecord({
    required this.driverId,
    required this.lockToken,
    required this.lockedAt,
  });
}

class DemoOrderLockStore {
  final Map<String, DemoOrderLockRecord> _locks = {};
  int _sequence = 0;

  DemoOrderLockRecord? ownerOf(String orderNumber) => _locks[orderNumber];

  void preLock(String orderNumber, {required String driverId}) {
    _locks.putIfAbsent(
      orderNumber,
      () => _newRecord(orderNumber: orderNumber, driverId: driverId),
    );
  }

  DemoOrderLockRecord? tryAcquire({
    required String orderNumber,
    required String driverId,
  }) {
    final current = _locks[orderNumber];
    if (current != null) {
      return current.driverId == driverId ? current : null;
    }

    final record = _newRecord(orderNumber: orderNumber, driverId: driverId);
    _locks[orderNumber] = record;
    return record;
  }

  DemoOrderLockRecord _newRecord({
    required String orderNumber,
    required String driverId,
  }) {
    _sequence += 1;
    return DemoOrderLockRecord(
      driverId: driverId,
      lockToken: 'demo-lock-$orderNumber-$_sequence',
      lockedAt: DateTime.now(),
    );
  }
}

class DemoDriverOrderAcceptanceRepository
    implements DriverOrderAcceptanceRepository {
  static final DemoOrderLockStore _sharedLockStore = DemoOrderLockStore();

  final DemoOrderLockStore lockStore;
  final Duration responseDelay;
  final bool seedTakenOrder;

  DemoDriverOrderAcceptanceRepository({
    DemoOrderLockStore? lockStore,
    this.responseDelay = const Duration(milliseconds: 650),
    this.seedTakenOrder = true,
  }) : lockStore = lockStore ?? _sharedLockStore {
    if (seedTakenOrder) {
      this.lockStore.preLock('GD-3102', driverId: 'demo-other-driver');
    }
  }

  @override
  DriverOrderAcceptanceDataSource get source =>
      DriverOrderAcceptanceDataSource.demo;

  @override
  Future<DriverOrderAcceptanceResult> accept({
    required DriverOrderCandidate order,
    required String driverId,
  }) async {
    if (!order.isAvailable) {
      return const DriverOrderAcceptanceResult(
        outcome: DriverOrderAcceptanceOutcome.alreadyTaken,
        message: 'This order is no longer available.',
      );
    }

    // The in-memory lock acquisition is synchronous. Two demo drivers sharing
    // this store cannot both acquire the same order in the same event loop.
    final existing = lockStore.ownerOf(order.orderNumber);
    if (existing != null && existing.driverId != driverId) {
      await Future<void>.delayed(responseDelay);
      return const DriverOrderAcceptanceResult(
        outcome: DriverOrderAcceptanceOutcome.alreadyTaken,
        message: 'Another driver accepted this delivery first.',
      );
    }

    final lock = lockStore.tryAcquire(
      orderNumber: order.orderNumber,
      driverId: driverId,
    );

    if (lock == null) {
      await Future<void>.delayed(responseDelay);
      return const DriverOrderAcceptanceResult(
        outcome: DriverOrderAcceptanceOutcome.alreadyTaken,
        message: 'Another driver accepted this delivery first.',
      );
    }

    await Future<void>.delayed(responseDelay);

    return DriverOrderAcceptanceResult(
      outcome: DriverOrderAcceptanceOutcome.accepted,
      message: 'Delivery accepted and locked to this driver in the local demo.',
      lockToken: lock.lockToken,
      acceptedAt: lock.lockedAt,
    );
  }
}

class UnavailableDriverOrderAcceptanceRepository
    implements DriverOrderAcceptanceRepository {
  const UnavailableDriverOrderAcceptanceRepository();

  @override
  DriverOrderAcceptanceDataSource get source =>
      DriverOrderAcceptanceDataSource.api;

  @override
  Future<DriverOrderAcceptanceResult> accept({
    required DriverOrderCandidate order,
    required String driverId,
  }) async {
    return const DriverOrderAcceptanceResult(
      outcome: DriverOrderAcceptanceOutcome.serverFailure,
      message:
          'Could not confirm with Getin. This order was not accepted. Retry after the Laravel acceptance endpoint is connected.',
    );
  }
}

class DriverOrderAcceptanceRepositoryFactory {
  const DriverOrderAcceptanceRepositoryFactory._();

  static DriverOrderAcceptanceRepository create(AppConfig config) {
    return switch (config.environment) {
      AppEnvironment.development => DemoDriverOrderAcceptanceRepository(),
      AppEnvironment.staging ||
      AppEnvironment.production =>
        const UnavailableDriverOrderAcceptanceRepository(),
    };
  }
}
