import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/active_delivery/driver_active_delivery_timeline_card.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';
import 'package:getin_driver/features/delivery_exceptions/domain/driver_delivery_exception_models.dart';
import 'package:getin_driver/features/delivery_exceptions/driver_delivery_exception_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/home/driver_home_dashboard.dart';

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

const delivery = DriverActiveDeliverySummary(
  orderNumber: 'GD-UAT-9001',
  status: 'Failed delivery • Demo',
  pickupBranch: 'Stanley',
  destinationArea: 'San Stefano',
  etaMinutes: 19,
  state: DriverDeliveryState.failedDelivery,
);

DriverDeliveryExceptionReceipt existingReceipt() =>
    DriverDeliveryExceptionReceipt(
      auditId: 'DEMO-EXCEPTION-GD-UAT-9001-1',
      orderNumber: 'GD-UAT-9001',
      driverReference: 'DEMO-DRIVER-001',
      reason: DriverDeliveryExceptionReason.customerUnavailable,
      note: 'Called customer twice, no answer.',
      reportedAt: DateTime(2026, 10, 6, 13, 41),
      latitude: 31.24580,
      longitude: 29.96680,
      recommendedOrderState: 'failed_delivery',
      serverAcknowledged: false,
      isDemo: true,
    );

void main() {
  setUp(DemoDriverDeliveryExceptionRepository.clearDemoState);

  testWidgets('Task 255 View Update Issue hydrates existing reason and note',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryExceptionScreen(
          delivery: delivery,
          config: config,
          repository: const DemoDriverDeliveryExceptionRepository(),
          existingReceipt: existingReceipt(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Update delivery issue'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.text('Update Exception'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Called customer twice, no answer.');
  });

  test('Task 255 demo update preserves the existing issue identity and note',
      () async {
    const repository = DemoDriverDeliveryExceptionRepository();
    final first = await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-UAT-9001',
      reason: DriverDeliveryExceptionReason.customerUnavailable,
      note: 'Called customer twice, no answer.',
    );

    final updated = await repository.reportException(
      apiOrderId: null,
      orderNumber: 'GD-UAT-9001',
      reason: DriverDeliveryExceptionReason.supportRequired,
      note: '',
    );

    expect(updated.receipt!.auditId, first.receipt!.auditId);
    expect(updated.receipt!.reportedAt, first.receipt!.reportedAt);
    expect(updated.receipt!.reason,
        DriverDeliveryExceptionReason.supportRequired);
    expect(updated.receipt!.note, 'Called customer twice, no answer.');
  });

  testWidgets(
      'Task 255 failed delivery does not show verification pending as completed',
      (tester) async {
    final pending = DriverDeliveryStateMachine.seed(
      orderNumber: 'GD-UAT-9001',
      currentState: DriverDeliveryState.verificationPending,
    );
    final failed = DriverDeliveryStateMachine.transition(
      timeline: pending,
      to: DriverDeliveryState.failedDelivery,
      source: 'delivery_exception',
      note: 'Customer unavailable',
    );
    expect(failed.isSuccess, isTrue);

    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverActiveDeliveryTimelineCard(timeline: failed.timeline),
        ),
      ),
    );

    expect(find.text('FAILED DELIVERY'), findsOneWidget);
    expect(find.text('Verification not completed'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(6));
  });

  testWidgets('Task 255 failed delivery home action uses problem-state wording',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverHomeDashboard(
            config: config,
            activeDeliveryOverride: delivery,
            onResumeActiveDelivery: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Failed Delivery'), findsOneWidget);
    expect(find.text('Resume Delivery'), findsNothing);
  });
}
