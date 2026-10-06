import '../../../core/config/app_config.dart';
import 'driver_runtime_recovery_store.dart';

typedef DriverRuntimeRecoveryRemoteLoader
    = Future<DriverRuntimeRecoverySnapshot> Function();
typedef DriverRuntimeRecoveryClock = DateTime Function();

enum DriverRuntimeRecoverySource {
  server,
  localCache,
  empty,
}

class DriverRuntimeRecoveryResolution {
  final DriverRuntimeRecoverySnapshot snapshot;
  final DriverRuntimeRecoverySource source;
  final bool readOnlyFallback;
  final String? warningMessage;

  const DriverRuntimeRecoveryResolution({
    required this.snapshot,
    required this.source,
    required this.readOnlyFallback,
    this.warningMessage,
  });
}

class DriverRuntimeRecoveryCoordinator {
  final AppConfig config;
  final DriverRuntimeRecoveryStore store;
  final DriverRuntimeRecoveryRemoteLoader? remoteLoader;
  final DriverRuntimeRecoveryClock clock;
  final Duration maxProductionCacheAge;

  const DriverRuntimeRecoveryCoordinator({
    required this.config,
    required this.store,
    this.remoteLoader,
    this.clock = DateTime.now,
    this.maxProductionCacheAge = const Duration(hours: 24),
  });

  Future<DriverRuntimeRecoveryResolution> resolve() async {
    final local = await _safeLocalLoad();

    if (config.allowsDemo || !config.isApiConfigured) {
      return DriverRuntimeRecoveryResolution(
        snapshot: local,
        source: _isEmpty(local)
            ? DriverRuntimeRecoverySource.empty
            : DriverRuntimeRecoverySource.localCache,
        readOnlyFallback: false,
      );
    }

    final loadRemote = remoteLoader;
    if (loadRemote != null) {
      try {
        final remote = await loadRemote();
        await _safeSave(remote);
        return DriverRuntimeRecoveryResolution(
          snapshot: remote,
          source: DriverRuntimeRecoverySource.server,
          readOnlyFallback: false,
        );
      } catch (_) {
        // Production startup may continue from a recent local snapshot only as
        // a read-only continuity aid. Server-confirmed actions remain locked.
      }
    }

    final sanitized = _productionFallback(local);
    return DriverRuntimeRecoveryResolution(
      snapshot: sanitized,
      source: _isEmpty(sanitized)
          ? DriverRuntimeRecoverySource.empty
          : DriverRuntimeRecoverySource.localCache,
      readOnlyFallback: true,
      warningMessage: _isEmpty(sanitized)
          ? 'GETIN could not confirm your current delivery state. Reconnect before continuing delivery work.'
          : 'Showing the latest saved delivery state. Reconnect before confirming any delivery action.',
    );
  }

  Future<DriverRuntimeRecoverySnapshot> _safeLocalLoad() async {
    try {
      return await store.load();
    } catch (_) {
      return DriverRuntimeRecoverySnapshot.empty;
    }
  }

  DriverRuntimeRecoverySnapshot _productionFallback(
    DriverRuntimeRecoverySnapshot local,
  ) {
    final lastSync = local.lastSuccessfulSyncAt;
    final active = local.activeDelivery;
    if (active == null) {
      return local;
    }

    final fresh = lastSync != null &&
        clock().difference(lastSync).abs() <= maxProductionCacheAge;
    if (fresh) {
      return local;
    }

    return DriverRuntimeRecoverySnapshot(
      completedOrderNumber: local.completedOrderNumber,
      lastSuccessfulSyncAt: local.lastSuccessfulSyncAt,
    );
  }

  Future<void> _safeSave(DriverRuntimeRecoverySnapshot snapshot) async {
    try {
      await store.save(snapshot);
    } catch (_) {
      // Persistence failure must never replace an authoritative server result.
    }
  }

  bool _isEmpty(DriverRuntimeRecoverySnapshot value) {
    return value.activeDelivery == null &&
        value.completedOrderNumber == null &&
        value.lastSuccessfulSyncAt == null;
  }
}
