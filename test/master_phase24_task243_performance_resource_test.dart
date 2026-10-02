import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_controller.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_policy_repository.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_runner.dart';
import 'package:getin_driver/features/background_location/domain/driver_background_location_models.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/location/data/driver_location_sync_repository.dart';
import 'package:getin_driver/features/location/domain/driver_location_models.dart';

void main() {
  test('Task 243 coalesces GPS uploads to one in-flight plus latest fix', () async {
    final runner = _StreamRunner();
    final sync = _BlockingSyncRepository();
    final controller = DriverBackgroundLocationController(
      policyRepository: const DemoDriverBackgroundLocationPolicyRepository(),
      runner: runner,
      locationSyncRepository: sync,
    );
    addTearDown(() async {
      controller.dispose();
      await runner.close();
    });

    await controller.updateContext(
      const DriverBackgroundLocationContext(
        availability: DriverAvailabilityState.online,
        hasActiveDelivery: true,
        internetConnected: true,
        gpsState: DriverGpsState.ready,
      ),
    );

    runner.add(_fix(31.201));
    await Future<void>.delayed(Duration.zero);
    expect(sync.calls, hasLength(1));

    runner.add(_fix(31.202));
    runner.add(_fix(31.203));
    await Future<void>.delayed(Duration.zero);
    expect(sync.calls, hasLength(1));

    sync.releaseFirst.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(sync.calls, hasLength(2));
    expect(sync.calls.last.coordinates.latitude, 31.203);
  });
}

DriverGpsFix _fix(double latitude) => DriverGpsFix(
      coordinates: DriverCoordinates(
        latitude: latitude,
        longitude: 29.95,
      ),
      accuracyMeters: 7,
      capturedAt: DateTime.now(),
      state: DriverGpsState.ready,
    );

class _StreamRunner implements DriverBackgroundLocationRunner {
  final StreamController<DriverGpsFix> controller =
      StreamController<DriverGpsFix>.broadcast();

  @override
  DriverBackgroundLocationRunnerSource get source =>
      DriverBackgroundLocationRunnerSource.device;

  @override
  Stream<DriverGpsFix> watch(DriverBackgroundLocationSettings settings) =>
      controller.stream;

  void add(DriverGpsFix fix) => controller.add(fix);

  Future<void> close() => controller.close();
}

class _BlockingSyncRepository implements DriverLocationSyncRepository {
  final Completer<void> releaseFirst = Completer<void>();
  final List<DriverGpsFix> calls = <DriverGpsFix>[];

  @override
  Future<void> sync(DriverGpsFix fix) async {
    calls.add(fix);
    if (calls.length == 1) {
      await releaseFirst.future;
    }
  }
}
