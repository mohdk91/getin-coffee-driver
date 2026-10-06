import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import 'domain/driver_delivery_state_machine.dart';

class DriverActiveDeliveryTimelineCard extends StatefulWidget {
  final DriverDeliveryTimeline timeline;
  final String? currentStateLabelOverride;
  final bool initiallyExpanded;

  const DriverActiveDeliveryTimelineCard({
    super.key,
    required this.timeline,
    this.currentStateLabelOverride,
    this.initiallyExpanded = true,
  });

  @override
  State<DriverActiveDeliveryTimelineCard> createState() =>
      _DriverActiveDeliveryTimelineCardState();
}

class _DriverActiveDeliveryTimelineCardState
    extends State<DriverActiveDeliveryTimelineCard> {
  late bool _expanded = widget.initiallyExpanded;

  int get _currentIndex {
    final current = widget.timeline.currentState;
    final index = DriverDeliveryStateMachine.corePath.indexOf(current);
    if (index >= 0) return index;

    var lastVisited = 0;
    for (var i = 0; i < DriverDeliveryStateMachine.corePath.length; i++) {
      if (widget.timeline.hasVisited(DriverDeliveryStateMachine.corePath[i])) {
        lastVisited = i;
      }
    }
    return lastVisited;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.timeline.currentState;
    final progress = (_currentIndex + 1)
        .clamp(1, DriverDeliveryStateMachine.corePath.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const ValueKey('delivery-timeline-toggle'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(.34),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.greenDark,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery timeline',
                          style: TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$progress of ${DriverDeliveryStateMachine.corePath.length} steps • ${widget.currentStateLabelOverride ?? current.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.greenDark,
                  ),
                ],
              ),
            ),
          ),
          if (!_expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatusPill(
                    label: (widget.currentStateLabelOverride ?? current.label)
                        .toUpperCase(),
                    tone: current.isProblemState
                        ? StatusTone.warning
                        : StatusTone.success,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Show timeline',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
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
                  label: (widget.currentStateLabelOverride ?? current.label)
                      .toUpperCase(),
                  tone: current.isProblemState
                      ? StatusTone.warning
                      : StatusTone.success,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...DriverDeliveryStateMachine.corePath.map(
              (state) {
                final verificationWasInterrupted = current.isProblemState &&
                    state == DriverDeliveryState.verificationPending &&
                    widget.timeline.hasVisited(state) &&
                    !widget.timeline.hasVisited(DriverDeliveryState.delivered);
                return _TimelineStep(
                  state: state,
                  current: current == state,
                  completed: widget.timeline.hasVisited(state) &&
                      current != state &&
                      !verificationWasInterrupted,
                  labelOverride: verificationWasInterrupted
                      ? 'Verification not completed'
                      : null,
                  currentLabelOverride: current == state
                      ? widget.currentStateLabelOverride
                      : null,
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
