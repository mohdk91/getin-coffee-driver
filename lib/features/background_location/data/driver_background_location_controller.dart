import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../location/domain/driver_location_models.dart';
import '../../location/data/driver_location_sync_repository.dart';
import '../domain/driver_background_location_models.dart';
import 'driver_background_location_policy_repository.dart';
import 'driver_background_location_runner.dart';

class DriverBackgroundLocationController extends ChangeNotifier {
  final DriverBackgroundLocationPolicyRepository policyRepository;
  final DriverBackgroundLocationRunner runner;
  final DriverLocationSyncRepository locationSyncRepository;

  DriverBackgroundTrackingSnapshot _snapshot =
      DriverBackgroundTrackingSnapshot.initial();
  DriverBackgroundLocationPolicy? _policy;
  StreamSubscription<DriverGpsFix>? _positionSubscription;
  DriverBackgroundLocationSettings? _runningSettings;
  int? _serverSyncGeneration;
  DriverGpsFix? _pendingServerFix;
  int _generation = 0;
  bool _disposed = false;

  DriverBackgroundLocationController({
    required this.policyRepository,
    required this.runner,
    this.locationSyncRepository = const NoopDriverLocationSyncRepository(),
  });

  DriverBackgroundTrackingSnapshot get snapshot => _snapshot;

  bool get isDeviceRunner =>
      runner.source == DriverBackgroundLocationRunnerSource.device;

  bool get isDemoPolicy =>
      policyRepository.source == DriverBackgroundLocationPolicySource.demo;

  Future<void> updateContext(DriverBackgroundLocationContext context) async {
    final generation = ++_generation;
    var policy = _policy;

    if (policy == null) {
      final result = await policyRepository.loadPolicy();
      if (_disposed || generation != _generation) return;
      if (!result.isSuccess) {
        await _stopSubscription();
        _setSnapshot(
          DriverBackgroundTrackingSnapshot(
            status: DriverBackgroundTrackingStatus.blocked,
            reason: DriverBackgroundTrackingReason.policyUnavailable,
            message: result.errorMessage ??
                'Background location policy is unavailable.',
            serverSyncAllowed: false,
            policy: null,
            settings: null,
            lastFix: _snapshot.lastFix,
            updatedAt: DateTime.now(),
          ),
        );
        return;
      }
      policy = result.policy!;
      _policy = policy;
    }

    final decision = DriverBackgroundLocationPolicyEvaluator.evaluate(
      policy: policy,
      context: context,
    );

    if (!decision.shouldTrack || decision.settings == null) {
      await _stopSubscription();
      if (_disposed || generation != _generation) return;
      _setSnapshot(
        DriverBackgroundTrackingSnapshot(
          status: decision.reason == DriverBackgroundTrackingReason.gpsNotReady
              ? DriverBackgroundTrackingStatus.blocked
              : DriverBackgroundTrackingStatus.stopped,
          reason: decision.reason,
          message: decision.message,
          serverSyncAllowed: decision.serverSyncAllowed,
          policy: policy,
          settings: null,
          lastFix: _snapshot.lastFix,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    if (_positionSubscription != null &&
        _runningSettings == decision.settings) {
      _setSnapshot(
        _snapshot.copyWith(
          status: DriverBackgroundTrackingStatus.tracking,
          reason: decision.reason,
          message: decision.message,
          serverSyncAllowed: decision.serverSyncAllowed,
          policy: policy,
          settings: decision.settings,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    await _stopSubscription();
    if (_disposed || generation != _generation) return;

    _runningSettings = decision.settings;
    _setSnapshot(
      DriverBackgroundTrackingSnapshot(
        status: DriverBackgroundTrackingStatus.starting,
        reason: decision.reason,
        message: 'Starting background location…',
        serverSyncAllowed: decision.serverSyncAllowed,
        policy: policy,
        settings: decision.settings,
        lastFix: _snapshot.lastFix,
        updatedAt: DateTime.now(),
      ),
    );

    try {
      _positionSubscription = runner.watch(decision.settings!).listen(
        (fix) {
          if (_disposed || generation != _generation) return;
          _setSnapshot(
            DriverBackgroundTrackingSnapshot(
              status: DriverBackgroundTrackingStatus.tracking,
              reason: decision.reason,
              message: decision.message,
              serverSyncAllowed: decision.serverSyncAllowed,
              policy: policy,
              settings: decision.settings,
              lastFix: fix,
              updatedAt: DateTime.now(),
            ),
          );
          if (decision.serverSyncAllowed) {
            _queueServerFix(fix, generation);
          }
        },
        onError: (Object _) {
          if (_disposed || generation != _generation) return;
          _setSnapshot(
            DriverBackgroundTrackingSnapshot(
              status: DriverBackgroundTrackingStatus.error,
              reason: DriverBackgroundTrackingReason.error,
              message:
                  'Background GPS stopped unexpectedly. Open GPS & Service Region, verify permissions, then retry.',
              serverSyncAllowed: false,
              policy: policy,
              settings: decision.settings,
              lastFix: _snapshot.lastFix,
              updatedAt: DateTime.now(),
            ),
          );
        },
      );

      if (runner.source == DriverBackgroundLocationRunnerSource.device) {
        _setSnapshot(
          _snapshot.copyWith(
            status: DriverBackgroundTrackingStatus.tracking,
            reason: decision.reason,
            message: decision.message,
            serverSyncAllowed: decision.serverSyncAllowed,
            policy: policy,
            settings: decision.settings,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _runningSettings = null;
      _setSnapshot(
        DriverBackgroundTrackingSnapshot(
          status: DriverBackgroundTrackingStatus.error,
          reason: DriverBackgroundTrackingReason.error,
          message:
              'Background GPS could not start. Check location services and background permission, then retry.',
          serverSyncAllowed: false,
          policy: policy,
          settings: decision.settings,
          lastFix: _snapshot.lastFix,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _queueServerFix(DriverGpsFix fix, int generation) {
    if (_disposed || generation != _generation) return;

    // Keep only the newest unsent fix while one upload is in flight. This
    // avoids parallel GPS requests on slow networks without sending stale
    // intermediate positions after connectivity recovers.
    _pendingServerFix = fix;
    if (_serverSyncGeneration == generation) return;

    _serverSyncGeneration = generation;
    unawaited(_drainServerFixes(generation));
  }

  Future<void> _drainServerFixes(int generation) async {
    try {
      while (!_disposed && generation == _generation) {
        final fix = _pendingServerFix;
        if (fix == null) return;
        _pendingServerFix = null;
        await _syncServerFix(fix, generation);
      }
    } finally {
      if (_serverSyncGeneration == generation) {
        _serverSyncGeneration = null;
      }
    }
  }

  Future<void> _syncServerFix(DriverGpsFix fix, int generation) async {
    try {
      await locationSyncRepository.sync(fix);
      if (_disposed || generation != _generation) return;
      _setSnapshot(
        _snapshot.copyWith(
          lastServerSyncAt: DateTime.now(),
          clearServerSyncError: true,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _setSnapshot(
        _snapshot.copyWith(
          serverSyncError:
              'GPS is active on this device, but the latest position did not reach GETIN.',
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> stop({
    String message = 'Background location is stopped.',
  }) async {
    ++_generation;
    _pendingServerFix = null;
    await _stopSubscription();
    if (_disposed) return;
    _setSnapshot(
      _snapshot.copyWith(
        status: DriverBackgroundTrackingStatus.stopped,
        reason: DriverBackgroundTrackingReason.driverNotOnline,
        message: message,
        serverSyncAllowed: false,
        clearSettings: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _stopSubscription() async {
    _pendingServerFix = null;
    final subscription = _positionSubscription;
    _positionSubscription = null;
    _runningSettings = null;
    await subscription?.cancel();
  }

  void _setSnapshot(DriverBackgroundTrackingSnapshot value) {
    if (_disposed) return;
    _snapshot = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _pendingServerFix = null;
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = null;
    _runningSettings = null;
    super.dispose();
  }
}

class DriverBackgroundLocationControllerFactory {
  const DriverBackgroundLocationControllerFactory._();

  static DriverBackgroundLocationController create(AppConfig config) {
    const useRealDeviceGpsInDevelopment = bool.fromEnvironment(
      'DRIVER_REAL_BACKGROUND_GPS',
      defaultValue: false,
    );

    final useDeviceRunner = !config.allowsDemo ||
        useRealDeviceGpsInDevelopment;

    return DriverBackgroundLocationController(
      policyRepository:
          DriverBackgroundLocationPolicyRepositoryFactory.create(config),
      runner: useDeviceRunner
          ? const DeviceDriverBackgroundLocationRunner()
          : const DemoDriverBackgroundLocationRunner(),
      locationSyncRepository:
          DriverLocationSyncRepositoryFactory.create(config),
    );
  }
}
