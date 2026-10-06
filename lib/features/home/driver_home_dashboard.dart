import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/driver_v2_ui.dart';
import '../../core/widgets/status_pill.dart';
import '../active_delivery/domain/driver_delivery_state_machine.dart';
import '../availability/data/driver_availability_repository.dart';
import '../eligibility/data/driver_order_eligibility_repository.dart';
import 'data/driver_home_repository.dart';
import 'domain/driver_home_models.dart';

class DriverHomeDashboard extends StatefulWidget {
  final AppConfig config;
  final DriverHomeRepository repository;
  final DriverAvailabilityRepository availabilityRepository;
  final DriverOrderEligibilityRepository eligibilityRepository;
  final ValueChanged<DriverHomeSnapshot>? onSnapshotChanged;
  final VoidCallback? onResumeActiveDelivery;
  final VoidCallback? onOpenGpsServiceRegion;
  final VoidCallback? onOpenOrderEligibility;
  final VoidCallback? onOpenRatingsReviews;
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenEarnings;
  final VoidCallback? onOpenSupport;
  final String? completedOrderNumber;
  final int? unreadNotificationsOverride;
  final DriverActiveDeliverySummary? activeDeliveryOverride;
  final int reloadToken;
  final VoidCallback? onLoadFinished;

  const DriverHomeDashboard({
    super.key,
    required this.config,
    this.repository = const DemoDriverHomeRepository(),
    this.availabilityRepository = const DemoDriverAvailabilityRepository(),
    this.eligibilityRepository = const DemoDriverOrderEligibilityRepository(),
    this.onSnapshotChanged,
    this.onResumeActiveDelivery,
    this.onOpenGpsServiceRegion,
    this.onOpenOrderEligibility,
    this.onOpenRatingsReviews,
    this.onOpenOrders,
    this.onOpenEarnings,
    this.onOpenSupport,
    this.completedOrderNumber,
    this.unreadNotificationsOverride,
    this.activeDeliveryOverride,
    this.reloadToken = 0,
    this.onLoadFinished,
  });

  @override
  State<DriverHomeDashboard> createState() => _DriverHomeDashboardState();
}

class _DriverHomeDashboardState extends State<DriverHomeDashboard> {
  DriverHomeSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  bool _availabilityChanging = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DriverHomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  Future<void> _load() async {
    final existingAvailability = _snapshot?.availability;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await widget.repository.loadDashboard();
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _errorMessage = result.errorMessage ?? 'Could not load the dashboard.';
      });
      widget.onLoadFinished?.call();
      return;
    }

    var loaded = result.snapshot!;
    if (existingAvailability != null &&
        widget.availabilityRepository.source ==
            DriverAvailabilityDataSource.demo) {
      loaded = loaded.copyWith(availability: existingAvailability);
    }

    if (widget.unreadNotificationsOverride != null) {
      loaded = loaded.copyWith(
        unreadNotifications: widget.unreadNotificationsOverride,
      );
    }

    final completedOrderNumber = widget.completedOrderNumber;
    if (completedOrderNumber != null &&
        loaded.activeDelivery?.orderNumber == completedOrderNumber) {
      loaded = loaded.copyWith(
        clearActiveDelivery: true,
        completedToday: loaded.completedToday + 1,
        updatedAt: DateTime.now(),
      );
    }

    loaded = await _withEligibilityCount(loaded);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _snapshot = loaded;
    });

    widget.onSnapshotChanged?.call(loaded);
    widget.onLoadFinished?.call();
  }

  Future<DriverHomeSnapshot> _withEligibilityCount(
    DriverHomeSnapshot snapshot,
  ) async {
    final hasActiveDelivery = widget.activeDeliveryOverride != null ||
        snapshot.activeDelivery != null;
    final result = await widget.eligibilityRepository.evaluate(
      availability: snapshot.availability,
      activeOrderCount: hasActiveDelivery ? 1 : 0,
      driverApproved: true,
    );

    if (!result.isSuccess || hasActiveDelivery) {
      return snapshot.copyWith(availableOrders: 0);
    }

    return snapshot.copyWith(
      availableOrders: result.snapshot!.eligibleOrders.length,
    );
  }

  Future<void> _changeAvailability(DriverAvailabilityState requested) async {
    final snapshot = _snapshot;
    if (snapshot == null || _availabilityChanging) return;

    if (requested == snapshot.availability) return;

    setState(() => _availabilityChanging = true);

    final result = await widget.availabilityRepository.changeAvailability(
      currentState: snapshot.availability,
      requestedState: requested,
      hasActiveDelivery: widget.activeDeliveryOverride != null ||
          snapshot.activeDelivery != null,
    );

    if (!mounted) return;

    var updated = snapshot;
    if (result.isSuccess) {
      updated = snapshot.copyWith(
        availability: result.state,
        updatedAt: DateTime.now(),
      );
      updated = await _withEligibilityCount(updated);
      if (!mounted) return;
    }

    setState(() {
      _availabilityChanging = false;
      if (result.isSuccess) {
        _snapshot = updated;
      }
    });

    if (result.isSuccess) {
      widget.onSnapshotChanged?.call(updated);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const AppLoadingState(label: 'Loading driver dashboard…');
    }

    if (_snapshot == null) {
      return AppStateView.error(
        title: 'Dashboard unavailable',
        message: _errorMessage ?? 'Could not load your driver dashboard.',
        onRetry: _load,
      );
    }

    final storedSnapshot = _snapshot!;
    var snapshot = widget.unreadNotificationsOverride == null
        ? storedSnapshot
        : storedSnapshot.copyWith(
            unreadNotifications: widget.unreadNotificationsOverride,
          );
    final activeDeliveryOverride = widget.activeDeliveryOverride;
    if (activeDeliveryOverride != null) {
      snapshot = snapshot.copyWith(
        activeDelivery: activeDeliveryOverride,
        availableOrders: 0,
      );
    }
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
            padding: EdgeInsets.fromLTRB(padding, 14, padding, 32),
            children: [
              _HeaderSummary(snapshot: snapshot),
              if (snapshot.activeDelivery != null) ...[
                const SizedBox(height: 14),
                _ActiveDeliveryCard(
                  delivery: snapshot.activeDelivery!,
                  onResume: widget.onResumeActiveDelivery,
                ),
              ],
              const SizedBox(height: 20),
              const DriverSectionHeading(
                title: 'Quick actions',
                subtitle: 'The four things you need most during a shift.',
              ),
              const SizedBox(height: 10),
              _QuickActions(
                hasActiveDelivery: snapshot.activeDelivery != null,
                onOrders: widget.onOpenOrders,
                onNavigate: snapshot.activeDelivery != null
                    ? widget.onResumeActiveDelivery
                    : widget.onOpenGpsServiceRegion,
                onEarnings: widget.onOpenEarnings,
                onSupport: widget.onOpenSupport,
              ),
              const SizedBox(height: 20),
              const DriverSectionHeading(
                title: 'Today',
                subtitle: 'Your shift at a glance.',
              ),
              const SizedBox(height: 10),
              _DashboardMetrics(
                snapshot: snapshot,
                onOpenRatingsReviews: widget.onOpenRatingsReviews,
              ),
              const SizedBox(height: 14),
              _MotivationCard(snapshot: snapshot),
              const SizedBox(height: 20),
              const DriverSectionHeading(
                title: 'Availability',
                subtitle: 'Choose whether you can receive new delivery jobs.',
              ),
              const SizedBox(height: 10),
              _AvailabilityControl(
                snapshot: snapshot,
                changing: _availabilityChanging,
                isDemo: widget.availabilityRepository.source ==
                    DriverAvailabilityDataSource.demo,
                onChanged: _changeAvailability,
              ),
              const SizedBox(height: 20),
              const DriverSectionHeading(
                title: 'Driver status',
                subtitle: 'Location, connection and order eligibility.',
              ),
              const SizedBox(height: 10),
              _SystemStatusCard(
                snapshot: snapshot,
                onOpenGpsServiceRegion: widget.onOpenGpsServiceRegion,
                onOpenOrderEligibility: widget.onOpenOrderEligibility,
              ),
              const SizedBox(height: 14),
              Text(
                'Last refreshed ${_formatClock(snapshot.updatedAt)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatClock(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _HeaderSummary extends StatelessWidget {
  final DriverHomeSnapshot snapshot;

  const _HeaderSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final availabilityLabel = snapshot.availability.label;
    final availabilityTone = switch (snapshot.availability) {
      DriverAvailabilityState.online => StatusTone.success,
      DriverAvailabilityState.offline => StatusTone.neutral,
      DriverAvailabilityState.onBreak => StatusTone.warning,
    };
    final active = snapshot.activeDelivery;
    final compact = MediaQuery.sizeOf(context).width < 350;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 188 : 196),
        decoration: const BoxDecoration(
          color: AppColors.greenDark,
          image: DecorationImage(
            image: AssetImage('assets/images/branches/getin_stanley.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                AppColors.greenDark.withOpacity(.25),
                AppColors.greenDark.withOpacity(.88),
                AppColors.greenDark,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 15 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: availabilityLabel,
                      tone: availabilityTone,
                      icon: Icons.circle,
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.beige,
                        size: 23,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 44 : 58),
                Text(
                  active == null
                      ? 'Ready for your shift?'
                      : 'Delivery in progress',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: compact ? 24 : 27,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  active != null
                      ? '${active.orderNumber} • ${active.destinationArea} • ${active.etaMinutes} min'
                      : switch (snapshot.availability) {
                          DriverAvailabilityState.online =>
                            '${snapshot.availableOrders} eligible orders are ready when you are.',
                          DriverAvailabilityState.offline =>
                            'Go online when you are ready to receive delivery jobs.',
                          DriverAvailabilityState.onBreak =>
                            'Your break is active. Resume when you are ready.',
                        },
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: compact ? 11.5 : 12.5,
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

class _QuickActions extends StatelessWidget {
  final bool hasActiveDelivery;
  final VoidCallback? onOrders;
  final VoidCallback? onNavigate;
  final VoidCallback? onEarnings;
  final VoidCallback? onSupport;

  const _QuickActions({
    required this.hasActiveDelivery,
    this.onOrders,
    this.onNavigate,
    this.onEarnings,
    this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: DriverQuickActionTile(
                label: 'View orders',
                caption: 'New and active jobs',
                icon: Icons.receipt_long_outlined,
                onTap: onOrders,
                emphasized: hasActiveDelivery,
              ),
            ),
            SizedBox(
              width: width,
              child: DriverQuickActionTile(
                label: 'Navigate',
                caption: hasActiveDelivery ? 'Resume route' : 'Location & area',
                icon: Icons.navigation_rounded,
                onTap: onNavigate,
              ),
            ),
            SizedBox(
              width: width,
              child: DriverQuickActionTile(
                label: 'Earnings hub',
                caption: 'Today and payouts',
                icon: Icons.account_balance_wallet_outlined,
                onTap: onEarnings,
              ),
            ),
            SizedBox(
              width: width,
              child: DriverQuickActionTile(
                label: 'Support',
                caption: 'Get help quickly',
                icon: Icons.support_agent_rounded,
                onTap: onSupport,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final DriverHomeSnapshot snapshot;

  const _MotivationCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    const dailyTarget = 6;
    final completed = snapshot.completedToday.clamp(0, dailyTarget).toInt();
    final remaining = dailyTarget - completed;
    final progress = completed / dailyTarget;
    final message = remaining == 0
        ? 'Daily goal reached. Great shift — keep your quality and rating high.'
        : '$remaining ${remaining == 1 ? 'delivery' : 'deliveries'} to reach today’s ${dailyTarget}-delivery goal.';

    return DriverProgressCard(
      eyebrow: 'Today’s goal',
      title: '$completed / $dailyTarget deliveries',
      message: message,
      progress: progress,
      icon: remaining == 0 ? Icons.emoji_events_rounded : Icons.bolt_rounded,
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;
  final VoidCallback? onResume;

  const _ActiveDeliveryCard({required this.delivery, this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withOpacity(.55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D211C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusPill(
                label: 'ACTIVE DELIVERY',
                tone: StatusTone.info,
                icon: Icons.route_rounded,
              ),
              const Spacer(),
              Text(
                '${delivery.etaMinutes} min',
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            delivery.orderNumber,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            delivery.status,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          _RouteRow(
            icon: Icons.storefront_rounded,
            label: 'Pickup',
            value: delivery.pickupBranch,
          ),
          const SizedBox(height: 9),
          _RouteRow(
            icon: Icons.location_on_outlined,
            label: 'Destination',
            value: delivery.destinationArea,
          ),
          const SizedBox(height: 12),
          Text(
            'Complete ${delivery.orderNumber} before receiving another delivery offer.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onResume != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onResume,
                icon: Icon(
                  delivery.resolvedState == DriverDeliveryState.failedDelivery
                      ? Icons.report_problem_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  delivery.resolvedState == DriverDeliveryState.failedDelivery
                      ? 'View Failed Delivery'
                      : delivery.resolvedState ==
                              DriverDeliveryState.returnedToBranch
                          ? 'View Return to Branch'
                          : 'Resume Delivery',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.green, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
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
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  final DriverHomeSnapshot snapshot;
  final VoidCallback? onOpenRatingsReviews;
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenEarnings;
  final VoidCallback? onOpenSupport;

  const _DashboardMetrics({
    required this.snapshot,
    this.onOpenRatingsReviews,
    this.onOpenOrders,
    this.onOpenEarnings,
    this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 350;
    final metrics = [
      _MetricData(
        icon: Icons.local_shipping_outlined,
        label: 'Available orders',
        value: snapshot.availableOrders.toString(),
        caption: 'Eligible demo jobs',
      ),
      _MetricData(
        icon: Icons.check_circle_outline_rounded,
        label: 'Completed today',
        value: snapshot.completedToday.toString(),
        caption: 'Demo deliveries',
      ),
      _MetricData(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Earnings today',
        value:
            '${snapshot.currencyCode} ${snapshot.earningsToday.toStringAsFixed(0)}',
        caption: 'Demo earnings',
      ),
      _MetricData(
        icon: Icons.star_rounded,
        label: 'Rating',
        value: snapshot.rating.toStringAsFixed(1),
        caption: '${snapshot.ratingCount} ratings',
        onTap: onOpenRatingsReviews,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _MetricCard(data: metrics[index]),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 122,
      ),
      itemBuilder: (context, index) => _MetricCard(data: metrics[index]),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, color: AppColors.green, size: 20),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (data.onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -.25,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (data.onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: data.onTap,
      child: card,
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  final DriverHomeSnapshot snapshot;
  final VoidCallback? onOpenGpsServiceRegion;
  final VoidCallback? onOpenOrderEligibility;

  const _SystemStatusCard({
    required this.snapshot,
    this.onOpenGpsServiceRegion,
    this.onOpenOrderEligibility,
  });

  @override
  Widget build(BuildContext context) {
    final gps = _gpsPresentation(snapshot.gpsState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusRow(
              icon: gps.icon,
              label: 'GPS',
              value: gps.label,
              tone: gps.tone,
            ),
            const Divider(height: 22),
            _StatusRow(
              icon: snapshot.internetConnected
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              label: 'Internet',
              value: snapshot.internetConnected ? 'Connected' : 'Offline',
              tone: snapshot.internetConnected
                  ? StatusTone.success
                  : StatusTone.danger,
            ),
            const Divider(height: 22),
            _StatusRow(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              value: snapshot.unreadNotifications == 0
                  ? 'No unread alerts'
                  : '${snapshot.unreadNotifications} unread',
              tone: snapshot.unreadNotifications == 0
                  ? StatusTone.neutral
                  : StatusTone.info,
            ),
            if (onOpenGpsServiceRegion != null) ...[
              const Divider(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenGpsServiceRegion,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('GPS & Service Region'),
                ),
              ),
            ],
            if (onOpenOrderEligibility != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenOrderEligibility,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Smart Order Eligibility'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _GpsPresentation _gpsPresentation(DriverGpsState state) {
    return switch (state) {
      DriverGpsState.ready => const _GpsPresentation(
          label: 'Ready',
          tone: StatusTone.success,
          icon: Icons.gps_fixed_rounded,
        ),
      DriverGpsState.disabled => const _GpsPresentation(
          label: 'Disabled',
          tone: StatusTone.danger,
          icon: Icons.location_off_rounded,
        ),
      DriverGpsState.permissionDenied => const _GpsPresentation(
          label: 'Permission denied',
          tone: StatusTone.danger,
          icon: Icons.gpp_bad_outlined,
        ),
      DriverGpsState.backgroundPermissionDenied => const _GpsPresentation(
          label: 'Background denied',
          tone: StatusTone.warning,
          icon: Icons.layers_clear_outlined,
        ),
      DriverGpsState.stale => const _GpsPresentation(
          label: 'Stale location',
          tone: StatusTone.warning,
          icon: Icons.history_rounded,
        ),
      DriverGpsState.inaccurate => const _GpsPresentation(
          label: 'Low accuracy',
          tone: StatusTone.warning,
          icon: Icons.gps_not_fixed_rounded,
        ),
    };
  }
}

class _GpsPresentation {
  final String label;
  final StatusTone tone;
  final IconData icon;

  const _GpsPresentation({
    required this.label,
    required this.tone,
    required this.icon,
  });
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final StatusTone tone;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.green, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        StatusPill(label: value, tone: tone),
      ],
    );
  }
}

class _AvailabilityControl extends StatelessWidget {
  final DriverHomeSnapshot snapshot;
  final bool changing;
  final bool isDemo;
  final ValueChanged<DriverAvailabilityState> onChanged;

  const _AvailabilityControl({
    required this.snapshot,
    required this.changing,
    required this.isDemo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveDelivery = snapshot.activeDelivery != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.toggle_on_rounded,
                color: AppColors.green,
                size: 24,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Shift availability',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isDemo)
                const StatusPill(
                  label: 'DEMO',
                  tone: StatusTone.info,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            hasActiveDelivery
                ? 'An active delivery is in progress. Offline is locked until it is completed. On Break stops new jobs, but the current delivery still remains required.'
                : 'Choose whether you are available for new delivery jobs.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              final controls = DriverAvailabilityState.values
                  .map(
                    (state) => _AvailabilityOption(
                      state: state,
                      selected: snapshot.availability == state,
                      changing: changing,
                      onTap: () => onChanged(state),
                    ),
                  )
                  .toList();

              if (compact) {
                return Column(
                  children: [
                    for (var i = 0; i < controls.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      controls[i],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < controls.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: controls[i]),
                  ],
                ],
              );
            },
          ),
          if (changing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (hasActiveDelivery) ...[
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  color: AppColors.warning,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline is blocked locally while this active delivery remains open. On Break can pause new jobs, but it never removes the responsibility to finish the active delivery. A future Laravel policy may support an operations-approved transfer.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityOption extends StatelessWidget {
  final DriverAvailabilityState state;
  final bool selected;
  final bool changing;
  final VoidCallback onTap;

  const _AvailabilityOption({
    required this.state,
    required this.selected,
    required this.changing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      DriverAvailabilityState.online => Icons.radio_button_checked_rounded,
      DriverAvailabilityState.offline => Icons.power_settings_new_rounded,
      DriverAvailabilityState.onBreak => Icons.free_breakfast_outlined,
    };

    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: changing ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          state.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? AppColors.white : AppColors.greenDark,
          backgroundColor: selected ? AppColors.greenDark : AppColors.cream,
          side: BorderSide(
            color: selected ? AppColors.greenDark : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
