import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';

void main() {
  group('Task 24 delivery state machine', () {
    test('rejects impossible accepted to delivered jump', () {
      final timeline = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-2481',
        currentState: DriverDeliveryState.accepted,
        occurredAt: DateTime(2026, 9, 26, 10),
      );

      final result = DriverDeliveryStateMachine.transition(
        timeline: timeline,
        to: DriverDeliveryState.delivered,
        source: 'test',
      );

      expect(result.isSuccess, isFalse);
      expect(result.timeline.currentState, DriverDeliveryState.accepted);
      expect(result.errorMessage, contains('accepted → delivered'));
    });

    test('advanceTo also refuses a large accepted to delivered skip', () {
      final timeline = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-2481',
        currentState: DriverDeliveryState.accepted,
      );

      final result = DriverDeliveryStateMachine.advanceTo(
        timeline: timeline,
        target: DriverDeliveryState.delivered,
        source: 'test',
      );

      expect(result.isSuccess, isFalse);
      expect(result.timeline.currentState, DriverDeliveryState.accepted);
      expect(result.errorMessage, contains('skips too many required states'));
    });

    test('rejects picked up to delivered jump', () {
      final timeline = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-2481',
        currentState: DriverDeliveryState.pickedUp,
      );

      final result = DriverDeliveryStateMachine.transition(
        timeline: timeline,
        to: DriverDeliveryState.delivered,
        source: 'test',
      );

      expect(result.isSuccess, isFalse);
      expect(result.timeline.currentState, DriverDeliveryState.pickedUp);
    });

    test('advanceTo records required customer verification states in order',
        () {
      final timeline = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-2481',
        currentState: DriverDeliveryState.outForDelivery,
        occurredAt: DateTime(2026, 9, 26, 11),
      );

      final result = DriverDeliveryStateMachine.advanceTo(
        timeline: timeline,
        target: DriverDeliveryState.verificationPending,
        source: 'customer_verification',
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.timeline.currentState,
        DriverDeliveryState.verificationPending,
      );
      expect(result.timeline.hasVisited(DriverDeliveryState.arrivedCustomer),
          isTrue);
      expect(
        result.timeline.hasVisited(DriverDeliveryState.verificationPending),
        isTrue,
      );
      expect(
        result.timeline.history
            .map((event) => event.state)
            .toList()
            .indexOf(DriverDeliveryState.arrivedCustomer),
        lessThan(
          result.timeline.history
              .map((event) => event.state)
              .toList()
              .indexOf(DriverDeliveryState.verificationPending),
        ),
      );
    });

    test('valid full delivery path reaches delivered sequentially', () {
      var timeline = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-2481',
        currentState: DriverDeliveryState.accepted,
      );

      for (final state in <DriverDeliveryState>[
        DriverDeliveryState.goingToBranch,
        DriverDeliveryState.arrivedAtBranch,
        DriverDeliveryState.pickedUp,
        DriverDeliveryState.outForDelivery,
        DriverDeliveryState.arrivedCustomer,
        DriverDeliveryState.verificationPending,
        DriverDeliveryState.delivered,
      ]) {
        final result = DriverDeliveryStateMachine.transition(
          timeline: timeline,
          to: state,
          source: 'test',
        );
        expect(result.isSuccess, isTrue, reason: state.wireValue);
        timeline = result.timeline;
      }

      expect(timeline.currentState, DriverDeliveryState.delivered);
      expect(timeline.currentState.isTerminal, isTrue);
    });

    test('return to branch is terminal and blocks normal progression', () {
      final start = DriverDeliveryStateMachine.seed(
        orderNumber: 'GD-2481',
        currentState: DriverDeliveryState.outForDelivery,
      );
      final returned = DriverDeliveryStateMachine.transition(
        timeline: start,
        to: DriverDeliveryState.returnedToBranch,
        source: 'delivery_exception',
      );
      expect(returned.isSuccess, isTrue);
      expect(returned.timeline.currentState.isProblemState, isTrue);

      final resume = DriverDeliveryStateMachine.transition(
        timeline: returned.timeline,
        to: DriverDeliveryState.arrivedCustomer,
        source: 'test',
      );
      expect(resume.isSuccess, isFalse);
      expect(
        resume.timeline.currentState,
        DriverDeliveryState.returnedToBranch,
      );
    });

    test('status mapper restores previous task labels safely', () {
      expect(
        driverDeliveryStateFromStatus('Going to branch'),
        DriverDeliveryState.goingToBranch,
      );
      expect(
        driverDeliveryStateFromStatus('Picked up • Demo'),
        DriverDeliveryState.pickedUp,
      );
      expect(
        driverDeliveryStateFromStatus('Out for delivery • Demo'),
        DriverDeliveryState.outForDelivery,
      );
    });
  });
}
