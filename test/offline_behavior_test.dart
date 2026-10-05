import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/navigation/driver_tab.dart';
import 'package:getin_driver/core/offline/driver_offline_safety.dart';
import 'package:getin_driver/core/widgets/driver_app_scaffold.dart';
import 'package:getin_driver/features/delivery_completion/data/driver_delivery_completion_repository.dart';
import 'package:getin_driver/features/delivery_completion/domain/driver_delivery_completion_models.dart';
import 'package:getin_driver/features/delivery_completion/driver_complete_delivery_card.dart';
import 'package:getin_driver/features/delivery_verification/domain/driver_delivery_pin_models.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

const _delivery = DriverActiveDeliverySummary(
  orderNumber: 'GD-2481',
  status: 'Verification pending',
  pickupBranch: 'Stanley',
  destinationArea: 'San Stefano',
  etaMinutes: 4,
);

DriverDeliveryPinReceipt _verification() {
  return DriverDeliveryPinReceipt(
    auditId: 'VERIFY-OFFLINE-1',
    orderNumber: 'GD-2481',
    customerReference: 'CUSTOMER-1',
    assignedDriverReference: 'DRIVER-1',
    verifiedAt: DateTime(2026, 9, 27, 1),
    verificationType: 'pin',
    serverAcknowledged: true,
    isDemo: false,
  );
}

class _CountingCompletionRepository
    implements DriverDeliveryCompletionRepository {
  int calls = 0;

  @override
  DriverDeliveryCompletionDataSource get source =>
      DriverDeliveryCompletionDataSource.api;

  @override
  Future<DriverDeliveryCompletionResult> completeDelivery({
    required int? apiOrderId,
    required String orderNumber,
    required DriverDeliveryPinReceipt verification,
  }) async {
    calls += 1;
    return const DriverDeliveryCompletionResult.failure(
      reason: DriverDeliveryCompletionFailureReason.unavailable,
      message: 'Should not be called while offline.',
    );
  }
}

void main() {
  test('Task 38 names every server-confirmed critical action', () {
    expect(DriverCriticalAction.values, hasLength(5));
    expect(DriverCriticalAction.acceptOrder.label, 'Accept Order');
    expect(
      DriverCriticalAction.receivedFromBranch.label,
      'Received from Branch',
    );
    expect(
      DriverCriticalAction.arriveAtCustomer.label,
      'Arrived at Customer',
    );
    expect(
      DriverCriticalAction.customerVerification.label,
      'Customer Verification',
    );
    expect(DriverCriticalAction.completeDelivery.label, 'Complete Delivery');
    expect(
      DriverCriticalAction.completeDelivery.offlineMessage,
      contains('no delivery state changed'),
    );
  });

  testWidgets('Task 38 keeps a persistent offline banner with safe retry',
      (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DriverAppScaffold(
          currentTab: DriverTab.orders,
          onTabChanged: (_) {},
          offline: true,
          lastSuccessfulSyncAt: DateTime(2026, 9, 26, 23, 45),
          onRetryConnection: () => retries += 1,
          body: const Center(child: Text('Cached order data')),
        ),
      ),
    );

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.textContaining('Cached read-only information'), findsOneWidget);
    expect(find.textContaining('Last sync'), findsOneWidget);
    expect(find.text('Cached order data'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('Task 38 blocks Complete Delivery before repository call',
      (tester) async {
    final repository = _CountingCompletionRepository();

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverCompleteDeliveryCard(
              delivery: _delivery,
              verification: _verification(),
              repository: repository,
              criticalActionGate: () => false,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Complete Delivery'));
    await tester.pump();

    expect(repository.calls, 0);
    expect(
      find.textContaining("You're offline. Complete Delivery"),
      findsOneWidget,
    );
    expect(find.text('Delivery Completed'), findsNothing);
  });
}
