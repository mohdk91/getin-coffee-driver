import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/status_pill.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_order_eligibility_repository.dart';
import 'domain/driver_order_eligibility_models.dart';

class DriverOrderEligibilityScreen extends StatefulWidget {
  final AppConfig config;
  final DriverOrderEligibilityRepository repository;
  final DriverAvailabilityState availability;
  final int activeOrderCount;
  final bool driverApproved;

  const DriverOrderEligibilityScreen({
    super.key,
    required this.config,
    required this.repository,
    required this.availability,
    required this.activeOrderCount,
    this.driverApproved = true,
  });

  @override
  State<DriverOrderEligibilityScreen> createState() =>
      _DriverOrderEligibilityScreenState();
}

class _DriverOrderEligibilityScreenState
    extends State<DriverOrderEligibilityScreen> {
  DriverOrderEligibilitySnapshot? _snapshot;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.repository.evaluate(
      availability: widget.availability,
      activeOrderCount: widget.activeOrderCount,
      driverApproved: widget.driverApproved,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _snapshot = result.snapshot;
      _error = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Order Eligibility')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const AppLoadingState(label: 'Checking order eligibility…');
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return AppStateView.error(
        title: 'Eligibility unavailable',
        message: _error ??
            'Getin could not safely determine which delivery jobs you may receive.',
        onRetry: _load,
      );
    }

    final padding = Responsive.horizontalPadding(context);
    final eligibleCount = snapshot.eligibleOrders.length;
    final evaluatedCount = snapshot.decisions.length;
    final filteredCount = snapshot.rejectedOrders.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
            children: [
              if (widget.repository.source ==
                  DriverOrderEligibilityDataSource.demo) ...[
                const _DemoEligibilityBanner(),
                const SizedBox(height: 14),
              ],
              _EligibilitySummaryCard(
                eligibleCount: eligibleCount,
                evaluatedCount: evaluatedCount,
                filteredCount: filteredCount,
                capacityFull: !snapshot.context.hasOrderCapacity,
              ),
              const SizedBox(height: 20),
              const Text(
                'Eligibility gates',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A job is exposed only when every required gate passes. Candidate-specific checks are evaluated before an order reaches the Available Orders screen.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _RulesCard(snapshot: snapshot),
              const SizedBox(height: 14),
              const _PrivacyCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoEligibilityBanner extends StatelessWidget {
  const _DemoEligibilityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(.35),
        border: Border.all(color: AppColors.beige),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.greenDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Test-mode eligibility uses local data in this non-production build.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilitySummaryCard extends StatelessWidget {
  final int eligibleCount;
  final int evaluatedCount;
  final int filteredCount;
  final bool capacityFull;

  const _EligibilitySummaryCard({
    required this.eligibleCount,
    required this.evaluatedCount,
    required this.filteredCount,
    required this.capacityFull,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusPill(
            label: 'SERVER-READY FILTER',
            tone: StatusTone.info,
            icon: Icons.filter_alt_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            '$eligibleCount eligible now',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$evaluatedCount candidate jobs evaluated • $filteredCount filtered out',
            style: const TextStyle(
              color: AppColors.beige,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (capacityFull) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Active-order capacity is full. V1 allows one active delivery, so no new jobs are exposed until the current delivery is completed.',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  final DriverOrderEligibilitySnapshot snapshot;

  const _RulesCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final decisions = snapshot.decisions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: DriverOrderEligibilityRule.values
              .map((rule) => _aggregate(rule, decisions))
              .map((item) => _RuleSummaryRow(item: item))
              .expand((row) => [row, const Divider(height: 18)])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }

  _RuleAggregate _aggregate(
    DriverOrderEligibilityRule rule,
    List<DriverOrderEligibilityDecision> decisions,
  ) {
    if (decisions.isEmpty) {
      return _RuleAggregate(rule: rule, passed: 0, total: 0);
    }

    var passed = 0;
    for (final decision in decisions) {
      final check = decision.checks.firstWhere((item) => item.rule == rule);
      if (check.passed) passed++;
    }
    return _RuleAggregate(rule: rule, passed: passed, total: decisions.length);
  }
}

class _RuleAggregate {
  final DriverOrderEligibilityRule rule;
  final int passed;
  final int total;

  const _RuleAggregate({
    required this.rule,
    required this.passed,
    required this.total,
  });

  bool get allPass => total > 0 && passed == total;
}

class _RuleSummaryRow extends StatelessWidget {
  final _RuleAggregate item;

  const _RuleSummaryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.allPass
                ? const Color(0xFFEAF5EF)
                : const Color(0xFFFFF3E6),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            item.allPass ? Icons.check_rounded : Icons.filter_alt_off_outlined,
            color: item.allPass
                ? const Color(0xFF237A4B)
                : const Color(0xFFA86618),
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            item.rule.label,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${item.passed}/${item.total}',
          style: TextStyle(
            color: item.allPass ? const Color(0xFF237A4B) : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.green),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Eligibility uses operational order attributes only. Customer private details are intentionally not exposed before acceptance.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
