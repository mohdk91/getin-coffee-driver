import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/driver_v2_ui.dart';
import '../commissions/driver_commissions_screen.dart';
import 'data/driver_earnings_repository.dart';
import 'domain/driver_earnings_models.dart';

class DriverEarningsScreen extends StatefulWidget {
  final AppConfig config;
  final DriverEarningsRepository? repository;

  const DriverEarningsScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  late final DriverEarningsRepository _repository = widget.repository ??
      DriverEarningsRepositoryFactory.create(widget.config);
  DriverEarningsPeriod _period = DriverEarningsPeriod.today;
  DriverEarningsSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await _repository.load(_period);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _snapshot = result.snapshot;
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _changePeriod(DriverEarningsPeriod period) async {
    if (_period == period) return;
    setState(() => _period = period);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const AppLoadingState(label: 'Loading earnings…');
    }
    if (_snapshot == null) {
      return AppStateView.error(
        title: 'Earnings unavailable',
        message: _errorMessage ?? 'Could not load driver earnings.',
        onRetry: _load,
      );
    }

    final snapshot = _snapshot!;
    final padding = Responsive.horizontalPadding(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 18, padding, 28),
        children: [
          const DriverSectionHeading(
            title: 'Earnings',
            subtitle:
                'Track what you earned, what boosted it and every completed delivery.',
          ),
          const SizedBox(height: 14),
          _PeriodSelector(
            selected: _period,
            onSelected: _changePeriod,
          ),
          const SizedBox(height: 14),
          _TotalCard(snapshot: snapshot),
          if (_repository.source == DriverEarningsDataSource.demo &&
              _period == DriverEarningsPeriod.today) ...[
            const SizedBox(height: 12),
            _EarningsGoalCard(snapshot: snapshot),
          ],
          const SizedBox(height: 12),
          _CommissionPolicyEntry(config: widget.config),
          const SizedBox(height: 12),
          _EarningsTrendCard(snapshot: snapshot),
          const SizedBox(height: 12),
          _BreakdownSummary(snapshot: snapshot),
          const SizedBox(height: 20),
          DriverSectionHeading(
            title: 'Delivery earnings',
            subtitle: snapshot.deliveryCount == 1
                ? '1 completed delivery in this period.'
                : '${snapshot.deliveryCount} completed deliveries in this period.',
          ),
          const SizedBox(height: 10),
          if (snapshot.deliveries.isEmpty)
            const _EmptyEarningsCard()
          else
            ...snapshot.deliveries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DeliveryEarningCard(item: item),
              ),
            ),
          const SizedBox(height: 4),
          const _BackendRulesNote(),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final DriverEarningsPeriod selected;
  final ValueChanged<DriverEarningsPeriod> onSelected;

  const _PeriodSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: DriverEarningsPeriod.values.map((period) {
          final active = period == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: active ? AppColors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      color: active ? AppColors.white : AppColors.greenDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final DriverEarningsSnapshot snapshot;

  const _TotalCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final average = snapshot.deliveryCount == 0
        ? 0.0
        : snapshot.totalEarnings / snapshot.deliveryCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${snapshot.period.label} earnings',
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.beige,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${snapshot.currencyCode} ${snapshot.totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${snapshot.deliveryCount} completed deliveries',
            style: TextStyle(
              color: AppColors.white.withOpacity(.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Avg. / delivery',
                  value:
                      '${snapshot.currencyCode} ${average.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroMetric(
                  label: 'Bonuses + tips',
                  value:
                      '${snapshot.currencyCode} ${(snapshot.distanceBonusTotal + snapshot.peakBonusTotal + snapshot.tipTotal).toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withOpacity(.58),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsGoalCard extends StatelessWidget {
  final DriverEarningsSnapshot snapshot;

  const _EarningsGoalCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    const deliveryGoal = 6;
    final completed = snapshot.deliveryCount.clamp(0, deliveryGoal);
    final remaining = (deliveryGoal - completed).clamp(0, deliveryGoal);
    final progress = completed / deliveryGoal;

    return DriverProgressCard(
      eyebrow: 'Today’s delivery goal',
      title: '$completed / $deliveryGoal deliveries',
      message: remaining == 0
          ? 'Goal reached. Keep your service quality and rating high.'
          : '$remaining ${remaining == 1 ? 'delivery' : 'deliveries'} to reach today’s goal.',
      progress: progress,
      icon: remaining == 0 ? Icons.emoji_events_rounded : Icons.bolt_rounded,
    );
  }
}

class _EarningsTrendCard extends StatelessWidget {
  final DriverEarningsSnapshot snapshot;

  const _EarningsTrendCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final recent =
        snapshot.deliveries.reversed.take(7).toList().reversed.toList();
    final maxValue = recent.fold<double>(
      0,
      (current, item) =>
          item.totalEarning > current ? item.totalEarning : current,
    );

    return DriverSurfaceCard(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Earnings activity',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  snapshot.period.label,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (recent.isEmpty)
            const SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  'Complete a delivery to start your earnings trend.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 86,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: recent.map((item) {
                  final ratio = maxValue <= 0
                      ? .12
                      : (item.totalEarning / maxValue)
                          .clamp(.12, 1.0)
                          .toDouble();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Tooltip(
                        message:
                            '${item.orderNumber} • ${item.currencyCode} ${item.totalEarning.toStringAsFixed(2)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: ratio,
                                  widthFactor: .72,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _trendLabel(item.deliveredAt, snapshot.period),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Average ${snapshot.currencyCode} ${snapshot.deliveryCount == 0 ? '0.00' : (snapshot.totalEarnings / snapshot.deliveryCount).toStringAsFixed(2)} per delivery',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownSummary extends StatelessWidget {
  final DriverEarningsSnapshot snapshot;

  const _BreakdownSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final currency = snapshot.currencyCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Base earnings',
            value: '$currency ${snapshot.baseTotal.toStringAsFixed(2)}',
          ),
          _SummaryRow(
            label: 'Distance bonus',
            value:
                '$currency ${snapshot.distanceBonusTotal.toStringAsFixed(2)}',
          ),
          _SummaryRow(
            label: 'Peak bonus',
            value: '$currency ${snapshot.peakBonusTotal.toStringAsFixed(2)}',
          ),
          _SummaryRow(
            label: 'Tips',
            value: snapshot.tipsSupported
                ? '$currency ${snapshot.tipTotal.toStringAsFixed(2)}'
                : 'Not supported',
          ),
          _SummaryRow(
            label: 'Adjustments',
            value: _signedMoney(currency, snapshot.adjustmentTotal),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      margin: EdgeInsets.only(bottom: last ? 0 : 10),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionPolicyEntry extends StatelessWidget {
  final AppConfig config;

  const _CommissionPolicyEntry({required this.config});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DriverCommissionsScreen(config: config),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.rule_folder_outlined,
                color: AppColors.green,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver commissions',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'See how delivery pay, bonuses and approved adjustments are calculated.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.greenDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryEarningCard extends StatelessWidget {
  final DriverDeliveryEarning item;

  const _DeliveryEarningCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = item.currencyCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.orderNumber,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.pickupBranch} → ${item.destinationArea}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateTime(item.deliveredAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$currency ${item.totalEarning.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LineItem(
            label: 'Base earning',
            value: '$currency ${item.baseEarning.toStringAsFixed(2)}',
          ),
          _LineItem(
            label: 'Distance bonus',
            value: '$currency ${item.distanceBonus.toStringAsFixed(2)}',
          ),
          _LineItem(
            label: 'Peak bonus',
            value: '$currency ${item.peakBonus.toStringAsFixed(2)}',
          ),
          _LineItem(
            label: 'Tip',
            value: item.tipsSupported
                ? '$currency ${item.tipAmount!.toStringAsFixed(2)}'
                : 'Not supported',
          ),
          _LineItem(
            label: 'Adjustments',
            value: _signedMoney(currency, item.adjustments),
          ),
          if (item.adjustmentNote != null && item.adjustments != 0) ...[
            const SizedBox(height: 5),
            Text(
              item.adjustmentNote!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Divider(height: 20, color: AppColors.border),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total driver earning',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$currency ${item.totalEarning.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final String value;

  const _LineItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEarningsCard extends StatelessWidget {
  const _EmptyEarningsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.payments_outlined, color: AppColors.muted),
          SizedBox(height: 8),
          Text(
            'No completed deliveries in this period.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendRulesNote extends StatelessWidget {
  const _BackendRulesNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rule_rounded, color: AppColors.green, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your earnings may include base pay, distance, peak bonuses, tips and approved adjustments.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _signedMoney(String currency, double value) {
  if (value > 0) return '+$currency ${value.toStringAsFixed(2)}';
  if (value < 0) return '-$currency ${value.abs().toStringAsFixed(2)}';
  return '$currency 0.00';
}

String _trendLabel(DateTime value, DriverEarningsPeriod period) {
  final local = value.toLocal();
  if (period == DriverEarningsPeriod.today) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  if (period == DriverEarningsPeriod.week) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[local.weekday - 1];
  }

  return '${local.day}/${local.month}';
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} • $hour:$minute';
}
