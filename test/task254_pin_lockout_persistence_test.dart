import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/uat/driver_uat_pin_lockout_store.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';
import 'package:getin_driver/features/delivery_verification/driver_delivery_pin_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
    uatDemoRequested: true,
  );
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-UAT-9001',
    status: 'Out for delivery • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  Future<DriverDeliveryPinChallenge> loadChallenge(
    DemoDriverDeliveryPinRepository repository,
  ) async {
    final load = await repository.loadChallenge(
      apiOrderId: null,
      orderNumber: delivery.orderNumber,
    );
    return load.challenge!;
  }

  Future<DriverDeliveryPinVerificationResult> verify(
    DemoDriverDeliveryPinRepository repository,
    DriverDeliveryPinChallenge challenge,
    String code,
  ) {
    return repository.verifyPin(
      apiOrderId: null,
      challenge: challenge,
      orderNumber: challenge.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: code,
    );
  }

  test('Task 254 exhausted PIN attempts survive reload and block correct PIN',
      () async {
    final store = MemoryDriverUatPinLockoutStore();
    final repository = DemoDriverDeliveryPinRepository(lockoutStore: store);
    final challenge = await loadChallenge(repository);

    expect((await verify(repository, challenge, '1111')).failureReason,
        DriverDeliveryPinFailureReason.invalidCode);
    expect((await verify(repository, challenge, '2222')).failureReason,
        DriverDeliveryPinFailureReason.invalidCode);
    expect((await verify(repository, challenge, '3333')).failureReason,
        DriverDeliveryPinFailureReason.tooManyAttempts);

    final reloaded = await loadChallenge(repository);
    expect(reloaded.isAttemptLocked, isTrue);
    expect(reloaded.remainingAttempts, 0);

    final correctAfterLockout = await verify(
      repository,
      reloaded,
      DemoDriverDeliveryPinRepository.demoCode,
    );
    expect(correctAfterLockout.isSuccess, isFalse);
    expect(
      correctAfterLockout.failureReason,
      DriverDeliveryPinFailureReason.tooManyAttempts,
    );
  });

  test('Task 254 UAT PIN lockout survives a persisted store restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final firstStore = SharedPreferencesDriverUatPinLockoutStore(
      forcePersistenceInTests: true,
    );
    final firstRepository =
        DemoDriverDeliveryPinRepository(lockoutStore: firstStore);
    final challenge = await loadChallenge(firstRepository);

    await verify(firstRepository, challenge, '1111');
    await verify(firstRepository, challenge, '2222');
    final third = await verify(firstRepository, challenge, '3333');
    expect(
      third.failureReason,
      DriverDeliveryPinFailureReason.tooManyAttempts,
    );

    final restartedStore = SharedPreferencesDriverUatPinLockoutStore(
      forcePersistenceInTests: true,
    );
    final restartedRepository =
        DemoDriverDeliveryPinRepository(lockoutStore: restartedStore);
    final restartedChallenge = await loadChallenge(restartedRepository);

    expect(restartedChallenge.isAttemptLocked, isTrue);
    final correctAfterRestart = await verify(
      restartedRepository,
      restartedChallenge,
      DemoDriverDeliveryPinRepository.demoCode,
    );
    expect(correctAfterRestart.isSuccess, isFalse);
    expect(
      correctAfterRestart.failureReason,
      DriverDeliveryPinFailureReason.tooManyAttempts,
    );
  });

  test('Task 254 explicit UAT reset can clear a persisted PIN lockout',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPreferencesDriverUatPinLockoutStore(
      forcePersistenceInTests: true,
    );
    final repository = DemoDriverDeliveryPinRepository(lockoutStore: store);
    final challenge = await loadChallenge(repository);

    await verify(repository, challenge, '1111');
    await verify(repository, challenge, '2222');
    await verify(repository, challenge, '3333');
    expect((await loadChallenge(repository)).isAttemptLocked, isTrue);

    await store.clearAll();
    final freshRepository = DemoDriverDeliveryPinRepository(
      lockoutStore: SharedPreferencesDriverUatPinLockoutStore(
        forcePersistenceInTests: true,
      ),
    );
    expect((await loadChallenge(freshRepository)).isAttemptLocked, isFalse);
  });

  testWidgets('Task 254 refresh lockout status cannot re-enable PIN entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = DemoDriverDeliveryPinRepository(
      lockoutStore: MemoryDriverUatPinLockoutStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryPinScreen(
          config: config,
          delivery: delivery,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> wrongAttempt(String code, {required bool retry}) async {
      await tester.enterText(find.byType(TextField), code);
      final verifyButton = find.widgetWithText(FilledButton, 'Verify Delivery');
      await tester.ensureVisible(verifyButton);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();
      if (retry) {
        final retryButton = find.text('Try Code Again');
        await tester.ensureVisible(retryButton);
        await tester.tap(retryButton);
        await tester.pumpAndSettle();
      }
    }

    await wrongAttempt('1111', retry: true);
    await wrongAttempt('2222', retry: true);
    await wrongAttempt('3333', retry: false);

    expect(find.text('Too many attempts'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    final refresh = find.text('Refresh Lockout Status');
    await tester.ensureVisible(refresh);
    await tester.tap(refresh);
    await tester.pumpAndSettle();

    expect(find.text('Too many attempts'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    final verifyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verify Delivery'),
    );
    expect(verifyButton.onPressed, isNull);
  });
}
