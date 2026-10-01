import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import 'data/driver_order_contents_repository.dart';
import 'domain/driver_order_contents_models.dart';

class DriverOrderContentsScreen extends StatefulWidget {
  final AppConfig config;
  final String orderNumber;
  final int? apiOrderId;
  final DriverOrderContentsRepository? repository;

  const DriverOrderContentsScreen({
    super.key,
    required this.config,
    required this.orderNumber,
    this.apiOrderId,
    this.repository,
  });

  @override
  State<DriverOrderContentsScreen> createState() =>
      _DriverOrderContentsScreenState();
}

class _DriverOrderContentsScreenState extends State<DriverOrderContentsScreen> {
  late final DriverOrderContentsRepository _repository = widget.repository ??
      DriverOrderContentsRepositoryFactory.create(widget.config);

  DriverOrderContents? _contents;
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

    final result = await _repository.load(orderNumber: widget.orderNumber);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _contents = result.contents;
      _errorMessage = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Order Contents')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _contents == null) {
      return const AppLoadingState(label: 'Loading order contents…');
    }

    if (_contents == null) {
      return AppStateView.error(
        title: 'Order contents unavailable',
        message: _errorMessage ??
            'Getin could not confirm the transport summary for this order.',
        onRetry: _load,
      );
    }

    final contents = _contents!;
    final padding = Responsive.horizontalPadding(context);
    final isDemo = _repository.source == DriverOrderContentsDataSource.demo;

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
              _HeaderCard(contents: contents, isDemo: isDemo),
              const SizedBox(height: 14),
              _CountsCard(contents: contents),
              const SizedBox(height: 14),
              _InstructionCard(
                icon: Icons.inventory_2_outlined,
                title: 'Handling instructions',
                items: contents.handlingInstructions,
                emptyLabel: 'No special handling instructions.',
              ),
              const SizedBox(height: 14),
              _InstructionCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Customer delivery notes',
                items: contents.customerDeliveryNotes,
                emptyLabel: 'No delivery-relevant customer notes.',
              ),
              const SizedBox(height: 14),
              const _PrivacyCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DriverOrderContents contents;
  final bool isDemo;

  const _HeaderCard({required this.contents, required this.isDemo});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  contents.orderNumber,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (isDemo) const _DemoDataPill(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Read-only transport summary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withOpacity(0.78),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DemoDataPill extends StatelessWidget {
  const _DemoDataPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Demo data',
        style: TextStyle(
          color: AppColors.greenDark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CountsCard extends StatelessWidget {
  final DriverOrderContents contents;

  const _CountsCard({required this.contents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CountMetric(
              icon: Icons.shopping_bag_outlined,
              value: '${contents.bagCount}',
              label: contents.bagCount == 1 ? 'Bag' : 'Bags',
            ),
          ),
          Container(width: 1, height: 54, color: AppColors.border),
          Expanded(
            child: _CountMetric(
              icon: Icons.receipt_long_outlined,
              value: '${contents.itemCount}',
              label: contents.itemCount == 1 ? 'Item' : 'Items',
            ),
          ),
        ],
      ),
    );
  }
}

class _CountMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CountMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.green, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.greenDark,
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final String emptyLabel;

  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

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
            children: [
              Icon(icon, color: AppColors.green, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.greenDark,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Only delivery-relevant information is shown. Customer profile, account, payment, and other private details stay hidden.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.greenDark,
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
