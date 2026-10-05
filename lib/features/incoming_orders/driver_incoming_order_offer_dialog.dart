import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../eligibility/domain/driver_order_eligibility_models.dart';

enum DriverIncomingOfferDecision { accept, decline, expired }

Future<DriverIncomingOfferDecision?> showDriverIncomingOrderOfferDialog({
  required BuildContext context,
  required DriverOrderCandidate order,
  Duration offerDuration = const Duration(seconds: 25),
  bool uatDemo = false,
}) {
  HapticFeedback.heavyImpact();
  SystemSound.play(SystemSoundType.alert);
  return showDialog<DriverIncomingOfferDecision>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DriverIncomingOrderOfferDialog(
      order: order,
      offerDuration: offerDuration,
      uatDemo: uatDemo,
    ),
  );
}

class DriverIncomingOrderOfferDialog extends StatefulWidget {
  final DriverOrderCandidate order;
  final Duration offerDuration;
  final bool uatDemo;

  const DriverIncomingOrderOfferDialog({
    super.key,
    required this.order,
    this.offerDuration = const Duration(seconds: 25),
    this.uatDemo = false,
  });

  @override
  State<DriverIncomingOrderOfferDialog> createState() =>
      _DriverIncomingOrderOfferDialogState();
}

class _DriverIncomingOrderOfferDialogState
    extends State<DriverIncomingOrderOfferDialog> {
  Timer? _timer;
  late int _remainingSeconds;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    final requestedSeconds = widget.offerDuration.inSeconds;
    _totalSeconds = requestedSeconds < 1
        ? 1
        : requestedSeconds > 3600
            ? 3600
            : requestedSeconds;
    _remainingSeconds = _totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        Navigator.of(context).pop(DriverIncomingOfferDecision.expired);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish(DriverIncomingOfferDecision decision) {
    _timer?.cancel();
    Navigator.of(context).pop(decision);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final progress = _remainingSeconds / _totalSeconds;
    final compact = MediaQuery.sizeOf(context).width < 380;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 22,
          vertical: 20,
        ),
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 18 : 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.greenDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.beige,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEW DELIVERY',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '00:${_remainingSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.uatDemo) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(.42),
                      border: Border.all(color: AppColors.beige),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: AppColors.greenDark,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'UAT DEMO • No production order or customer data is used.',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.border,
                    color: _remainingSeconds <= 7
                        ? AppColors.warning
                        : AppColors.green,
                  ),
                ),
                const SizedBox(height: 18),
                _RoutePoint(
                  icon: Icons.storefront_rounded,
                  label: 'PICKUP',
                  value: order.pickupBranch,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 2,
                    height: 18,
                    alignment: Alignment.centerLeft,
                    color: AppColors.border,
                  ),
                ),
                _RoutePoint(
                  icon: Icons.location_on_rounded,
                  label: 'DELIVER TO',
                  value: order.destinationArea,
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 360;
                    final metrics = [
                      _Metric(
                        icon: Icons.schedule_rounded,
                        label: 'ETA',
                        value: order.estimatedDurationMinutes > 0
                            ? '~${order.estimatedDurationMinutes} min'
                            : '—',
                      ),
                      _Metric(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Bags',
                        value: '${order.bagCount}',
                      ),
                      _Metric(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Earning',
                        value:
                            '${order.currencyCode} ${order.estimatedDriverEarning.toStringAsFixed(2)}',
                      ),
                    ];
                    if (narrow) {
                      return Column(
                        children: [
                          for (final metric in metrics) ...[
                            metric,
                            if (metric != metrics.last)
                              const SizedBox(height: 8),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < metrics.length; i++) ...[
                          Expanded(child: metrics[i]),
                          if (i != metrics.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _finish(DriverIncomingOfferDecision.accept),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Accept Order'),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: () => _finish(DriverIncomingOfferDecision.decline),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Decline'),
                ),
                const SizedBox(height: 11),
                const Text(
                  'The first eligible driver whose acceptance is confirmed by Getin receives the delivery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RoutePoint({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.greenDark, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.greenDark, size: 19),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
