import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/push/driver_push_coordinator.dart';
import 'package:getin_driver/core/push/driver_push_models.dart';

void main() {
  test('Task 285 queues a terminated push until the app shell can consume it',
      () {
    final coordinator = DriverPushCoordinator.instance;
    coordinator.resetForTest();

    const intent = DriverPushIntent(
      origin: DriverPushOrigin.terminatedTap,
      type: 'order_available',
      offerId: 44,
      orderId: 11,
    );
    coordinator.publish(intent);

    final pending = coordinator.takePending();
    expect(pending, hasLength(1));
    expect(pending.single.offerId, 44);
    expect(coordinator.takePending(), isEmpty);
  });

  test('Task 285 streams foreground pushes when the app shell is listening',
      () async {
    final coordinator = DriverPushCoordinator.instance;
    coordinator.resetForTest();
    final completer = Completer<DriverPushIntent>();
    final subscription = coordinator.stream.listen((intent) {
      if (!completer.isCompleted) completer.complete(intent);
    });

    const intent = DriverPushIntent(
      origin: DriverPushOrigin.foreground,
      type: 'order_available',
      offerId: 55,
    );
    coordinator.publish(intent);

    expect((await completer.future).offerId, 55);
    expect(coordinator.takePending(), isEmpty);
    await subscription.cancel();
  });

  test('Task 285 production order push is server-authoritative', () {
    final shell = File(
      'lib/features/foundation/driver_foundation_shell.dart',
    ).readAsStringSync();

    expect(shell, contains('_handlePushIntent'));
    expect(shell, contains('_showProductionIncomingOffer'));
    expect(shell, contains('_eligibilityRepository.evaluate'));
    expect(shell, contains('_offerResponseRepository.reject'));
    expect(shell, contains('_acceptanceRepository.accept'));
    expect(shell, contains('DriverTab.orders'));
    expect(shell, contains('uatDemo: false'));
  });
}
