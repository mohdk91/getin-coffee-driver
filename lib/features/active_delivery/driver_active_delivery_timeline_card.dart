import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import 'domain/driver_delivery_state_machine.dart';

class DriverActiveDeliveryTimelineCard extends StatelessWidget {
  final DriverDeliveryTimeline timeline;
  final String? currentStateLabelOverride;

  const DriverActiveDeliveryTimelineCard({
    super.key,
    required this.timeline,
    this.currentStateLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final current = timeline.currentState;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Active Delivery Timeline',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: (currentStateLabelOverride ?? current.label)
                    .toUpperCase(),
                tone: current.isProblemState
                    ? StatusTone.warning
                    : StatusTone.success,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Getin enforces each custody state in order. Impossible state jumps are blocked.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...DriverDeliveryStateMachine.corePath.map(
            (state) {
              final verificationWasInterrupted = current.isProblemState &&
                  state == DriverDeliveryState.verificationPending &&
                  timeline.hasVisited(state) &&
                  !timeline.hasVisited(DriverDeliveryState.delivered);
              return _TimelineStep(
                state: state,
                current: current == state,
                completed: timeline.hasVisited(state) &&
                    current != state &&
                    !verificationWasInterrupted,
                labelOverride: verificationWasInterrupted
                    ? 'Verification not completed'
                    : null,
                currentLabelOverride:
                    current == state ? currentStateLabelOverride : null,
              );
            },
          ),
          if (current.isProblemState) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withOpacity(.20)),
              ),
              child: Text(
                '${current.label} is a terminal/problem state. Normal delivery progression is locked until operations resolves the order.',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 10.5,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final DriverDeliveryState state;
  final bool current;
  final bool completed;
  final String? labelOverride;
  final String? currentLabelOverride;

  const _TimelineStep({
    required this.state,
    required this.current,
    required this.completed,
    this.labelOverride,
    this.currentLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final active = current || completed;
    final icon = completed
        ? Icons.check_rounded
        : current
            ? Icons.navigation_rounded
            : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.green : AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.green : AppColors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 13,
              color: active ? AppColors.white : AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              currentLabelOverride ?? labelOverride ?? state.label,
              style: TextStyle(
                color: current ? AppColors.greenDark : AppColors.muted,
                fontSize: 11.5,
                fontWeight: current ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          if (current)
            const Text(
              'CURRENT',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
        ],
      ),
    );
  }
}
