import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import 'data/driver_commission_repository.dart';
import 'domain/driver_commission_models.dart';

class DriverCommissionsScreen extends StatefulWidget {
  final AppConfig config;
  final DriverCommissionRepository? repository;

  const DriverCommissionsScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverCommissionsScreen> createState() =>
      _DriverCommissionsScreenState();
}

class _DriverCommissionsScreenState extends State<DriverCommissionsScreen> {
  late final DriverCommissionRepository _repository = widget.repository ??
      DriverCommissionRepositoryFactory.create(widget.config);

  DriverCommissionPolicy? _policy;
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

    final result = await _repository.loadPolicy();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _policy = result.policy;
      _errorMessage = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _policy == null) {
      return const Scaffold(
        body: SafeArea(
          child: AppLoadingState(label: 'Loading commission policy…'),
        ),
      );
    }

    if (_policy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Commissions')),
        body: SafeArea(
          child: AppStateView.error(
            title: 'Commission policy unavailable',
            message: _errorMessage ?? 'Could not load commission policy.',
            onRetry: _load,
          ),
        ),
      );
    }

    final policy = _policy!;
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Commissions')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 28),
          children: [
            const Text(
              'Commission policy',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'See the rules currently supplied to the Driver App. Getin operations and Laravel remain the source of truth.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (_repository.source == DriverCommissionDataSource.demo) ...[
              const SizedBox(height: 10),
              const Text(
                'DEMO COMMISSION POLICY • Not a production payout promise',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _PolicySummaryCard(policy: policy),
            const SizedBox(height: 14),
            const _BackendAuthorityCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Active rules',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${policy.activeRules.length} rules',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...policy.activeRules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommissionRuleCard(rule: rule),
              ),
            ),
            const SizedBox(height: 4),
            const _AuditNote(),
          ],
        ),
      ),
    );
  }
}

class _PolicySummaryCard extends StatelessWidget {
  final DriverCommissionPolicy policy;

  const _PolicySummaryCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current policy',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            policy.policyVersion,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _PolicyInfoRow(
            label: 'Currency',
            value: policy.currencyCode,
          ),
          _PolicyInfoRow(
            label: 'Effective from',
            value: _formatDate(policy.effectiveFrom),
          ),
          _PolicyInfoRow(
            label: 'Effective until',
            value: policy.effectiveUntil == null
                ? 'Until replaced by backend'
                : _formatDate(policy.effectiveUntil!),
          ),
          _PolicyInfoRow(
            label: 'Last refreshed',
            value: _formatDateTime(policy.updatedAt),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _PolicyInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _PolicyInfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.beige,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendAuthorityCard extends StatelessWidget {
  const _BackendAuthorityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.green),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Backend is the source of truth',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _AuthorityLine(
            icon: Icons.cloud_done_outlined,
            text: 'Laravel supplies the active commission policy and amounts.',
          ),
          _AuthorityLine(
            icon: Icons.history_rounded,
            text:
                'Effective dates and historical rule snapshots remain auditable.',
          ),
          _AuthorityLine(
            icon: Icons.lock_outline_rounded,
            text: 'Flutter cannot edit commission rules or payout adjustments.',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _AuthorityLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool last;

  const _AuthorityLine({
    required this.icon,
    required this.text,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionRuleCard extends StatelessWidget {
  final DriverCommissionRule rule;

  const _CommissionRuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForCategory(rule.category),
                  color: AppColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.title,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rule.category.label,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            rule.calculationLabel,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rule.description,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditNote extends StatelessWidget {
  const _AuditNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined, color: AppColors.green, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Every completed delivery should retain the commission-policy version and returned payout components used at that time. Future rule changes must not silently rewrite historical earnings.',
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

IconData _iconForCategory(DriverCommissionRuleCategory category) {
  return switch (category) {
    DriverCommissionRuleCategory.baseEarning => Icons.payments_outlined,
    DriverCommissionRuleCategory.distanceBonus => Icons.route_outlined,
    DriverCommissionRuleCategory.peakBonus => Icons.bolt_outlined,
    DriverCommissionRuleCategory.tip => Icons.volunteer_activism_outlined,
    DriverCommissionRuleCategory.adjustment => Icons.tune_rounded,
  };
}

String _formatDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_formatDate(value)} • $hour:$minute';
}
