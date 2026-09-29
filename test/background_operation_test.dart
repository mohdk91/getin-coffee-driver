import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_controller.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_policy_repository.dart';
import 'package:getin_driver/features/background_location/data/driver_background_location_runner.dart';
import 'package:getin_driver/features/background_location/domain/driver_background_location_models.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  const policy = DriverBackgroundLocationPolicy(
    version: 'test-v1',
    trackWhenOnline: true,
    trackDuringActiveDelivery: true,
    onlineInterval: Duration(seconds: 30),
    onlineDistanceFilterMeters: 25,
    activeDeliveryInterval: Duration(seconds: 10),
    activeDeliveryDistanceFilterMeters: 10,
  );

  test('Task 39 tracks Online driver when backend policy requires it', () {
    final decision = DriverBackgroundLocationPolicyEvaluator.evaluate(
      policy: policy,
      context: const DriverBackgroundLocationContext(
        availability: DriverAvailabilityState.online,
        hasActiveDelivery: false,
        internetConnected: true,
        gpsState: DriverGpsState.ready,
      ),
    );

    expect(decision.shouldTrack, isTrue);
    expect(decision.serverSyncAllowed, isTrue);
    expect(decision.reason, DriverBackgroundTrackingReason.onlinePolicy);
    expect(decision.settings?.interval, const Duration(seconds: 30));
    expect(decision.settings?.distanceFilterMeters, 25);
  });

  test('Task 39 keeps active-delivery GPS local while network is offline', () {
    final decision = DriverBackgroundLocationPolicyEvaluator.evaluate(
      policy: policy,
      context: const DriverBackgroundLocationContext(
        availability: DriverAvailabilityState.online,
        hasActiveDelivery: true,
        internetConnected: false,
        gpsState: DriverGpsState.ready,
      ),
    );

    expect(decision.shouldTrack, isTrue);
    expect(decision.serverSyncAllowed, isFalse);
    expect(decision.reason, DriverBackgroundTrackingReason.activeDelivery);
    expect(decision.settings?.activeDelivery, isTrue);
    expect(decision.settings?.interval, const Duration(seconds: 10));
  });

  test('Task 39 stops background GPS offline without active delivery', () {
    final decision = DriverBackgroundLocationPolicyEvaluator.evaluate(
      policy: policy,
      context: const DriverBackgroundLocationContext(
        availability: DriverAvailabilityState.online,
        hasActiveDelivery: false,
        internetConnected: false,
        gpsState: DriverGpsState.ready,
      ),
    );

    expect(decision.shouldTrack, isFalse);
    expect(
      decision.reason,
      DriverBackgroundTrackingReason.offlineNoActiveDelivery,
    );
  });

  test('Task 39 blocks tracking without background location permission', () {
    final decision = DriverBackgroundLocationPolicyEvaluator.evaluate(
      policy: policy,
      context: const DriverBackgroundLocationContext(
        availability: DriverAvailabilityState.online,
        hasActiveDelivery: true,
        internetConnected: true,
        gpsState: DriverGpsState.backgroundPermissionDenied,
      ),
    );

    expect(decision.shouldTrack, isFalse);
    expect(decision.reason, DriverBackgroundTrackingReason.gpsNotReady);
    expect(decision.message, contains('background permission denied'));
  });

  test('Task 39 controller applies battery profile and emits a demo fix',
      () async {
    final controller = DriverBackgroundLocationController(
      policyRepository: const DemoDriverBackgroundLocationPolicyRepository(),
      runner: const DemoDriverBackgroundLocationRunner(),
    );
    addTearDown(controller.dispose);

    await controller.updateContext(
      const DriverBackgroundLocationContext(
        availability: DriverAvailabilityState.online,
        hasActiveDelivery: true,
        internetConnected: true,
        gpsState: DriverGpsState.ready,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.snapshot.status,
      DriverBackgroundTrackingStatus.tracking,
    );
    expect(controller.snapshot.settings?.activeDelivery, isTrue);
    expect(controller.snapshot.lastFix, isNotNull);
    expect(controller.snapshot.serverSyncAllowed, isTrue);
  });
}
