import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../eligibility/data/driver_order_eligibility_repository.dart';
import '../eligibility/domain/driver_order_eligibility_models.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_order_acceptance_repository.dart';
import 'domain/driver_order_acceptance_models.dart';

class DriverAvailableOrdersScreen extends StatefulWidget {
  final AppConfig config;
  final DriverOrderEligibilityRepository repository;
  final DriverAvailabilityState availability;
  final int activeOrderCount;
  final bool driverApproved;
  final String? activeOrderNumber;
  final DriverOrderAcceptanceRepository? acceptanceRepository;
  final ValueChanged<DriverAcceptedOrder>? onOrderAccepted;
  final String searchQuery;
  final String? branchFilter;
  final bool hideForStatusFilter;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverAvailableOrdersScreen({
    super.key,
    required this.config,
    required this.repository,
    required this.availability,
    required this.activeOrderCount,
    this.driverApproved = true,
    this.activeOrderNumber,
    this.acceptanceRepository,
    this.onOrderAccepted,
    this.searchQuery = '',
    this.branchFilter,
    this.hideForStatusFilter = false,
    this.criticalActionGate,
  });

  @override
  State<DriverAvailableOrdersScreen> createState() =>
      _DriverAvailableOrdersScreenState();
}

class _DriverAvailableOrdersScreenState
    extends State<DriverAvailableOrdersScreen> {
  DriverOrderEligibilitySnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  late final DriverOrderAcceptanceRepository _acceptanceRepository;
  final Set<String> _acceptingOrders = <String>{};
  final Map<String, DriverOrderAcceptanceResult> _acceptanceResults =
      <String, DriverOrderAcceptanceResult>{};
  DriverAcceptedOrder? _acceptedOrder;

  @override
  void initState() {
    super.initState();
    _acceptanceRepository = widget.acceptanceRepository ??
        DriverOrderAcceptanceRepositoryFactory.create(widget.config);
    _load();
  }

  @override
  void didUpdateWidget(covariant DriverAvailableOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availability != widget.availability ||
        oldWidget.activeOrderCount != widget.activeOrderCount ||
        oldWidget.driverApproved != widget.driverApproved) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
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
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _acceptOrder(DriverOrderCandidate order) async {
    if (_acceptingOrders.isNotEmpty || _acceptedOrder != null) return;
    if (!driverCriticalActionAllowed(widget.criticalActionGate)) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(DriverCriticalAction.acceptOrder.offlineMessage),
        ),
      );
      return;
    }

    setState(() {
      _acceptingOrders.add(order.orderNumber);
      _acceptanceResults.remove(order.orderNumber);
    });

    final result = await _acceptanceRepository.accept(
      order: order,
      driverId: 'demo-driver-001',
    );
    if (!mounted) return;

    final acceptedOrder = result.isAccepted
        ? DriverAcceptedOrder(order: order, result: result)
        : null;

    setState(() {
      _acceptingOrders.remove(order.orderNumber);
      _acceptanceResults[order.orderNumber] = result;
      if (acceptedOrder != null) {
        _acceptedOrder = acceptedOrder;
      }
    });

    if (acceptedOrder != null) {
      widget.onOrderAccepted?.call(acceptedOrder);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(result.message),
      ),
    );
  }

  void _showDetails(DriverOrderCandidate order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const AppLoadingState(label: 'Checking available orders…');
    }

    if (_snapshot == null) {
      return AppStateView.error(
        title: 'Orders unavailable',
        message: _errorMessage ??
            'Getin could not confirm which delivery jobs are eligible.',
        onRetry: _load,
      );
    }

    final snapshot = _snapshot!;
    final query = widget.searchQuery.trim().toLowerCase();
    final eligibleOrders = snapshot.eligibleOrders.where((decision) {
      final order = decision.order;
      if (_acceptanceResults[order.orderNumber]?.outcome ==
          DriverOrderAcceptanceOutcome.alreadyTaken) {
        return false;
      }
      if (widget.hideForStatusFilter) return false;
      if (widget.branchFilter != null &&
          order.pickupBranch != widget.branchFilter) {
        return false;
      }
      if (query.isNotEmpty &&
          !order.orderNumber.toLowerCase().contains(query) &&
          !order.pickupBranch.toLowerCase().contains(query) &&
          !order.destinationArea.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList(growable: false);
    final padding = Responsive.horizontalPadding(context);

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
              _OrdersHeader(
                eligibleCount: eligibleOrders.length,
                availability: snapshot.context.availability,
              ),
              if (widget.repository.source ==
                  DriverOrderEligibilityDataSource.demo) ...[
                const SizedBox(height: 12),
                const _DemoOrdersBanner(),
              ],
              if (_acceptedOrder != null) ...[
                const SizedBox(height: 12),
                _AcceptedOrderBanner(acceptedOrder: _acceptedOrder!),
              ],
              const SizedBox(height: 18),
              if (eligibleOrders.isEmpty)
                _EmptyAvailableOrders(
                  snapshot: snapshot,
                  activeOrderNumber: widget.activeOrderNumber,
                  filtering: query.isNotEmpty ||
                      widget.branchFilter != null ||
                      widget.hideForStatusFilter,
                )
              else
                ...eligibleOrders.map(
                  (decision) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AvailableOrderCard(
                      order: decision.order,
                      accepting:
                          _acceptingOrders.contains(decision.order.orderNumber),
                      acceptanceLocked: _acceptingOrders.isNotEmpty &&
                              !_acceptingOrders
                                  .contains(decision.order.orderNumber) ||
                          (_acceptedOrder != null &&
                              _acceptedOrder!.order.orderNumber !=
                                  decision.order.orderNumber),
                      acceptanceResult:
                          _acceptanceResults[decision.order.orderNumber],
                      onAccept: () => _acceptOrder(decision.order),
                      onDetails: () => _showDetails(decision.order),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              const _PrivacyNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  final int eligibleCount;
  final DriverAvailabilityState availability;

  const _OrdersHeader({
    required this.eligibleCount,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available / New Orders',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 23,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                eligibleCount == 1
                    ? '1 delivery currently matches your operational eligibility.'
                    : '$eligibleCount deliveries currently match your operational eligibility.',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusPill(
          label: availability.label,
          tone: availability == DriverAvailabilityState.online
              ? StatusTone.success
              : StatusTone.warning,
          icon: availability == DriverAvailabilityState.online
              ? Icons.radio_button_checked_rounded
              : Icons.pause_circle_outline_rounded,
        ),
      ],
    );
  }
}

class _DemoOrdersBanner extends StatelessWidget {
  const _DemoOrdersBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'DEMO ORDERS • Jobs and atomic acceptance locks are simulated locally for development. No live Laravel order is offered, reserved, or changed.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableOrderCard extends StatelessWidget {
  final DriverOrderCandidate order;
  final bool accepting;
  final bool acceptanceLocked;
  final DriverOrderAcceptanceResult? acceptanceResult;
  final VoidCallback onAccept;
  final VoidCallback onDetails;

  const _AvailableOrderCard({
    required this.order,
    required this.accepting,
    required this.acceptanceLocked,
    required this.acceptanceResult,
    required this.onAccept,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${order.pickupBranch} → ${order.destinationArea}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _EarningBadge(order: order),
              ],
            ),
            const SizedBox(height: 15),
            _RouteSummary(order: order),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OrderFactChip(
                  icon: Icons.route_outlined,
                  label:
                      '${order.distanceToBranchKm.toStringAsFixed(1)} km to branch',
                ),
                _OrderFactChip(
                  icon: Icons.local_shipping_outlined,
                  label:
                      '${order.deliveryDistanceKm.toStringAsFixed(1)} km delivery',
                ),
                _OrderFactChip(
                  icon: Icons.schedule_rounded,
                  label: '${order.estimatedDurationMinutes} min',
                ),
                _OrderFactChip(
                  icon: Icons.shopping_bag_outlined,
                  label:
                      order.bagCount == 1 ? '1 bag' : '${order.bagCount} bags',
                ),
              ],
            ),
            if (acceptanceResult != null) ...[
              const SizedBox(height: 14),
              _AcceptanceFeedback(result: acceptanceResult!),
            ],
            const SizedBox(height: 16),
            GetinActionButton(
              label: accepting
                  ? 'Accepting…'
                  : acceptanceLocked
                      ? 'Acceptance locked'
                      : acceptanceResult?.isAccepted == true
                          ? 'Accepted'
                          : acceptanceResult?.canRetry == true
                              ? 'Retry Accept'
                              : acceptanceResult?.outcome ==
                                      DriverOrderAcceptanceOutcome.alreadyTaken
                                  ? 'Already Taken'
                                  : 'Accept Delivery',
              icon: accepting
                  ? Icons.hourglass_top_rounded
                  : acceptanceResult?.isAccepted == true
                      ? Icons.check_circle_rounded
                      : acceptanceResult?.canRetry == true
                          ? Icons.refresh_rounded
                          : Icons.check_circle_outline_rounded,
              onPressed: accepting ||
                      acceptanceLocked ||
                      acceptanceResult?.isAccepted == true ||
                      acceptanceResult?.outcome ==
                          DriverOrderAcceptanceOutcome.alreadyTaken
                  ? null
                  : onAccept,
            ),
            const SizedBox(height: 8),
            GetinActionButton(
              label: 'Details',
              icon: Icons.info_outline_rounded,
              onPressed: onDetails,
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedOrderBanner extends StatelessWidget {
  final DriverAcceptedOrder acceptedOrder;

  const _AcceptedOrderBanner({required this.acceptedOrder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFD7CC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.green, size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${acceptedOrder.order.orderNumber} accepted',
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The local demo lock is now owned by this driver. Use the Active Delivery bar to open the route to the pickup branch.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptanceFeedback extends StatelessWidget {
  final DriverOrderAcceptanceResult result;

  const _AcceptanceFeedback({required this.result});

  @override
  Widget build(BuildContext context) {
    final accepted = result.outcome == DriverOrderAcceptanceOutcome.accepted;
    final alreadyTaken =
        result.outcome == DriverOrderAcceptanceOutcome.alreadyTaken;
    final background = accepted
        ? const Color(0xFFEAF3EF)
        : alreadyTaken
            ? const Color(0xFFFFF1EC)
            : const Color(0xFFFFF8E8);
    final icon = accepted
        ? Icons.check_circle_rounded
        : alreadyTaken
            ? Icons.block_rounded
            : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.greenDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningBadge extends StatelessWidget {
  final DriverOrderCandidate order;

  const _EarningBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'EST. EARNING',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${order.currencyCode} ${order.estimatedDriverEarning.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final DriverOrderCandidate order;

  const _RouteSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Column(
            children: [
              Icon(Icons.storefront_outlined, color: AppColors.green, size: 19),
              SizedBox(height: 4),
              Icon(Icons.more_vert_rounded, color: AppColors.muted, size: 16),
              SizedBox(height: 4),
              Icon(Icons.location_on_outlined,
                  color: AppColors.green, size: 19),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.pickupBranch,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  order.destinationArea,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFactChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OrderFactChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.green, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAvailableOrders extends StatelessWidget {
  final DriverOrderEligibilitySnapshot snapshot;
  final String? activeOrderNumber;
  final bool filtering;

  const _EmptyAvailableOrders({
    required this.snapshot,
    this.activeOrderNumber,
    this.filtering = false,
  });

  @override
  Widget build(BuildContext context) {
    final contextData = snapshot.context;
    final message = filtering
        ? 'No available delivery matches your current search or filters.'
        : !contextData.hasOrderCapacity
            ? activeOrderNumber == null
                ? 'V1 allows one active delivery. Finish the current delivery before Getin exposes another job.'
                : 'V1 allows one active delivery. Finish $activeOrderNumber before Getin exposes another job.'
            : contextData.availability != DriverAvailabilityState.online
                ? 'Go Online before Getin can expose eligible delivery jobs.'
                : 'No delivery currently passes every eligibility rule. Pull down to check again.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.green,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            filtering
                ? 'No matching available orders'
                : 'No new orders right now',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.green, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Before acceptance, Getin shows only the operational information needed to evaluate the job. Customer name, phone and exact private address remain hidden.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
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

class _OrderDetailsSheet extends StatelessWidget {
  final DriverOrderCandidate order;

  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Delivery details',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _DetailRow(label: 'Pickup branch', value: order.pickupBranch),
            _DetailRow(label: 'Destination area', value: order.destinationArea),
            _DetailRow(
              label: 'Distance to branch',
              value: '${order.distanceToBranchKm.toStringAsFixed(1)} km',
            ),
            _DetailRow(
              label: 'Delivery distance',
              value: '${order.deliveryDistanceKm.toStringAsFixed(1)} km',
            ),
            _DetailRow(
              label: 'Estimated duration',
              value: '${order.estimatedDurationMinutes} min',
            ),
            _DetailRow(
              label: 'Order / bag count',
              value: order.bagCount == 1 ? '1 bag' : '${order.bagCount} bags',
            ),
            _DetailRow(
              label: 'Estimated driver earning',
              value:
                  '${order.currencyCode} ${order.estimatedDriverEarning.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 10),
            const _PrivacyNotice(),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
