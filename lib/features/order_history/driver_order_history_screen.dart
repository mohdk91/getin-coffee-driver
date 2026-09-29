import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/status_pill.dart';
import '../active_delivery/domain/driver_delivery_state_machine.dart';
import '../eligibility/data/driver_order_eligibility_repository.dart';
import '../home/domain/driver_home_models.dart';
import '../orders/data/driver_order_acceptance_repository.dart';
import '../orders/domain/driver_order_acceptance_models.dart';
import '../orders/driver_available_orders_screen.dart';
import 'data/driver_order_history_repository.dart';
import 'domain/driver_order_history_models.dart';

class DriverOrderHistoryScreen extends StatefulWidget {
  final AppConfig config;
  final DriverOrderEligibilityRepository eligibilityRepository;
  final DriverAvailabilityState availability;
  final DriverActiveDeliverySummary? activeDelivery;
  final bool driverApproved;
  final DriverOrderAcceptanceRepository? acceptanceRepository;
  final ValueChanged<DriverAcceptedOrder>? onOrderAccepted;
  final DriverOrderHistoryRepository? historyRepository;
  final DriverActiveDeliverySummary? lastCompletedDelivery;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverOrderHistoryScreen({
    super.key,
    required this.config,
    required this.eligibilityRepository,
    required this.availability,
    required this.activeDelivery,
    required this.driverApproved,
    this.acceptanceRepository,
    this.onOrderAccepted,
    this.historyRepository,
    this.lastCompletedDelivery,
    this.criticalActionGate,
  });

  @override
  State<DriverOrderHistoryScreen> createState() =>
      _DriverOrderHistoryScreenState();
}

class _DriverOrderHistoryScreenState extends State<DriverOrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  late final DriverOrderHistoryRepository _repository =
      widget.historyRepository ??
          DriverOrderHistoryRepositoryFactory.create(widget.config);
  final TextEditingController _searchController = TextEditingController();
  DriverOrderHistorySnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  DriverOrderHistoryDateFilter _dateFilter = DriverOrderHistoryDateFilter.all;
  String? _branchFilter;
  DriverDeliveryState? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await _repository.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _snapshot = result.snapshot;
      _errorMessage = result.errorMessage;
    });
  }

  bool _matchesDate(DateTime date) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    return switch (_dateFilter) {
      DriverOrderHistoryDateFilter.all => true,
      DriverOrderHistoryDateFilter.today => !date.isBefore(startToday),
      DriverOrderHistoryDateFilter.last7Days =>
        !date.isBefore(now.subtract(const Duration(days: 7))),
      DriverOrderHistoryDateFilter.last30Days =>
        !date.isBefore(now.subtract(const Duration(days: 30))),
    };
  }

  List<DriverOrderHistoryItem> _filtered(DriverOrderHistoryGroup group) {
    final query = _searchController.text.trim().toLowerCase();
    final base = <DriverOrderHistoryItem>[
      ...?_snapshot?.items,
      if (widget.activeDelivery != null)
        DriverOrderHistoryItem(
          orderNumber: widget.activeDelivery!.orderNumber,
          pickupBranch: widget.activeDelivery!.pickupBranch,
          destinationArea: widget.activeDelivery!.destinationArea,
          state: widget.activeDelivery!.resolvedState,
          occurredAt: DateTime.now(),
          bagCount: 0,
          driverEarning: 0,
          currencyCode: 'EGP',
        ),
      if (widget.lastCompletedDelivery != null)
        DriverOrderHistoryItem(
          orderNumber: widget.lastCompletedDelivery!.orderNumber,
          pickupBranch: widget.lastCompletedDelivery!.pickupBranch,
          destinationArea: widget.lastCompletedDelivery!.destinationArea,
          state: DriverDeliveryState.delivered,
          occurredAt: DateTime.now(),
          bagCount: 0,
          driverEarning: 0,
          currencyCode: 'EGP',
          note: 'Completed during this demo session.',
        ),
    ];

    final deduped = <String, DriverOrderHistoryItem>{};
    for (final item in base) {
      deduped[item.orderNumber] = item;
    }

    return deduped.values.where((item) {
      if (item.group != group) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.orderNumber.toLowerCase().contains(query) &&
          !item.pickupBranch.toLowerCase().contains(query) &&
          !item.destinationArea.toLowerCase().contains(query)) {
        return false;
      }
      if (_branchFilter != null && item.pickupBranch != _branchFilter) {
        return false;
      }
      if (_statusFilter != null && item.state != _statusFilter) {
        return false;
      }
      if (!_matchesDate(item.occurredAt)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  int get _activeFilterCount =>
      (_dateFilter != DriverOrderHistoryDateFilter.all ? 1 : 0) +
      (_branchFilter != null ? 1 : 0) +
      (_statusFilter != null ? 1 : 0);

  Future<void> _showFilters() async {
    final branches = <String>{
      ...?_snapshot?.branches,
      if (widget.activeDelivery != null) widget.activeDelivery!.pickupBranch,
    }.toList()
      ..sort();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Filter Orders',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greenDark)),
                const SizedBox(height: 16),
                DropdownButtonFormField<DriverOrderHistoryDateFilter>(
                  value: _dateFilter,
                  decoration: const InputDecoration(labelText: 'Date'),
                  items: DriverOrderHistoryDateFilter.values
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text(value.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() => _dateFilter = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _branchFilter,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  hint: const Text('All branches'),
                  items: branches
                      .map((branch) => DropdownMenuItem<String?>(
                            value: branch,
                            child: Text(branch),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setSheetState(() => _branchFilter = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DriverDeliveryState?>(
                  value: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  hint: const Text('All statuses'),
                  items: DriverDeliveryState.values
                      .map((status) => DropdownMenuItem<DriverDeliveryState?>(
                            value: status,
                            child: Text(status.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setSheetState(() => _statusFilter = value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () {
                    setSheetState(() {
                      _dateFilter = DriverOrderHistoryDateFilter.all;
                      _branchFilter = null;
                      _statusFilter = null;
                    });
                    setState(() {});
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 18, padding, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Orders',
                  style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text(
                  'New, active, delivered and cancelled deliveries in one place.',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              if (_repository.source == DriverOrderHistoryDataSource.demo) ...[
                const SizedBox(height: 10),
                const Text('DEMO HISTORY • Laravel is not connected',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search order number',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Badge(
                    isLabelVisible: _activeFilterCount > 0,
                    label: Text('$_activeFilterCount'),
                    child: IconButton.filledTonal(
                      tooltip: 'Filters',
                      onPressed: _showFilters,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.greenDark,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.green,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          tabs: const [
            Tab(text: 'New / Available'),
            Tab(text: 'Active / On Delivery'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              DriverAvailableOrdersScreen(
                config: widget.config,
                repository: widget.eligibilityRepository,
                availability: widget.availability,
                activeOrderCount: widget.activeDelivery == null ? 0 : 1,
                activeOrderNumber: widget.activeDelivery?.orderNumber,
                driverApproved: widget.driverApproved,
                acceptanceRepository: widget.acceptanceRepository,
                onOrderAccepted: widget.onOrderAccepted,
                searchQuery: _searchController.text,
                branchFilter: _branchFilter,
                hideForStatusFilter: _statusFilter != null &&
                    _statusFilter != DriverDeliveryState.available,
                criticalActionGate: widget.criticalActionGate,
              ),
              _historyBody(DriverOrderHistoryGroup.active),
              _historyBody(DriverOrderHistoryGroup.delivered),
              _historyBody(DriverOrderHistoryGroup.cancelled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _historyBody(DriverOrderHistoryGroup group) {
    if (_loading && _snapshot == null) {
      return const AppLoadingState(label: 'Loading order history…');
    }
    if (_snapshot == null) {
      return AppStateView.error(
          title: 'Order history unavailable',
          message: _errorMessage ?? 'Unable to load order history.',
          onRetry: _load);
    }
    final items = _filtered(group);
    if (items.isEmpty) {
      return AppStateView.empty(
        title: 'No matching orders',
        message:
            _activeFilterCount > 0 || _searchController.text.trim().isNotEmpty
                ? 'Try clearing a filter or changing the order-number search.'
                : 'There are no orders in this section yet.',
      );
    }
    final padding = Responsive.horizontalPadding(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _HistoryOrderCard(item: items[index]),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final DriverOrderHistoryItem item;
  const _HistoryOrderCard({required this.item});

  StatusTone get _tone => switch (item.state) {
        DriverDeliveryState.delivered => StatusTone.success,
        DriverDeliveryState.cancelled ||
        DriverDeliveryState.failedDelivery ||
        DriverDeliveryState.returnedToBranch =>
          StatusTone.danger,
        DriverDeliveryState.outForDelivery ||
        DriverDeliveryState.verificationPending =>
          StatusTone.info,
        _ => StatusTone.warning,
      };

  String _dateText(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(item.orderNumber,
                        style: const TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900))),
                StatusPill(label: item.state.label, tone: _tone),
              ],
            ),
            const SizedBox(height: 10),
            Text('${item.pickupBranch} → ${item.destinationArea}',
                style: const TextStyle(
                    color: AppColors.greenDark, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(_dateText(item.occurredAt),
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            if (item.note != null) ...[
              const SizedBox(height: 8),
              Text(item.note!,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12, height: 1.4)),
            ],
            if (item.driverEarning > 0 || item.bagCount > 0) ...[
              const Divider(height: 22),
              Row(
                children: [
                  if (item.bagCount > 0)
                    Text(
                        '${item.bagCount} ${item.bagCount == 1 ? 'bag' : 'bags'}',
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (item.driverEarning > 0)
                    Text(
                        '${item.currencyCode} ${item.driverEarning.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
