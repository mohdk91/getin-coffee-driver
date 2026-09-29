import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../active_delivery/domain/driver_delivery_state_machine.dart';
import '../active_delivery/driver_active_delivery_timeline_card.dart';
import '../delivery/data/driver_start_delivery_repository.dart';
import '../delivery/domain/driver_start_delivery_models.dart';
import '../delivery/driver_start_delivery_screen.dart';
import '../home/domain/driver_home_models.dart';
import '../navigation/data/driver_navigation_launcher.dart';
import '../navigation/data/driver_navigation_preference_store.dart';
import '../navigation/domain/driver_navigation_models.dart';
import '../navigation/driver_navigation_card.dart';
import '../order_contents/data/driver_order_contents_repository.dart';
import '../order_contents/driver_order_contents_screen.dart';
import '../pickup/data/driver_branch_pickup_repository.dart';
import '../pickup/domain/driver_branch_pickup_models.dart';
import '../pickup/driver_branch_pickup_verification_screen.dart';
import '../support/driver_support_chat_screen.dart';
import 'data/driver_branch_route_repository.dart';
import 'domain/driver_branch_route_models.dart';

class DriverRouteToBranchScreen extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary delivery;
  final DriverBranchRouteRepository? repository;
  final DriverBranchPickupRepository? pickupRepository;
  final DriverOrderContentsRepository? orderContentsRepository;
  final DriverStartDeliveryRepository? startDeliveryRepository;
  final DriverNavigationLauncher? navigationLauncher;
  final DriverNavigationPreferenceStore? navigationPreferenceStore;
  final DriverDeliveryTimeline? timeline;
  final VoidCallback? onSupport;
  final ValueChanged<DriverDeliveryState>? onStateChanged;
  final ValueChanged<DriverBranchPickupReceipt>? onPickupReceived;
  final ValueChanged<DriverStartDeliveryReceipt>? onDeliveryStarted;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverRouteToBranchScreen({
    super.key,
    required this.config,
    required this.delivery,
    this.repository,
    this.pickupRepository,
    this.orderContentsRepository,
    this.startDeliveryRepository,
    this.navigationLauncher,
    this.navigationPreferenceStore,
    this.timeline,
    this.onSupport,
    this.onStateChanged,
    this.onPickupReceived,
    this.onDeliveryStarted,
    this.criticalActionGate,
  });

  @override
  State<DriverRouteToBranchScreen> createState() =>
      _DriverRouteToBranchScreenState();
}

class _DriverRouteToBranchScreenState extends State<DriverRouteToBranchScreen> {
  late final DriverBranchRouteRepository _repository = widget.repository ??
      DriverBranchRouteRepositoryFactory.create(widget.config);
  DriverBranchRouteInfo? _route;
  String? _errorMessage;
  bool _loading = true;
  bool _pickupReceivedLocally = false;
  bool _deliveryStartedLocally = false;
  late DriverDeliveryTimeline _timeline;

  @override
  void initState() {
    super.initState();
    _timeline = widget.timeline ??
        DriverDeliveryStateMachine.seed(
          orderNumber: widget.delivery.orderNumber,
          currentState: widget.delivery.resolvedState,
        );
    _load();
  }

  bool _advanceTimeline(
    DriverDeliveryState target, {
    required String source,
    String? note,
  }) {
    final result = DriverDeliveryStateMachine.advanceTo(
      timeline: _timeline,
      target: target,
      source: source,
      note: note,
    );
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return false;
    }

    if (result.changed) {
      setState(() => _timeline = result.timeline);
      widget.onStateChanged?.call(target);
    }
    return true;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _repository.load(delivery: widget.delivery);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _route = result.route;
      _errorMessage = result.errorMessage;
    });
  }

  void _callBranch() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Demo only: the real branch phone number will come from Getin operations. No call was placed.',
        ),
      ),
    );
  }

  void _openSupport() {
    if (widget.onSupport != null) {
      widget.onSupport!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverSupportChatScreen(
          config: widget.config,
          delivery: widget.delivery,
        ),
      ),
    );
  }

  void _openPickupVerification() {
    final route = _route;
    if (route == null) return;
    if (!_advanceTimeline(
      DriverDeliveryState.arrivedAtBranch,
      source: 'branch_arrival',
      note: 'Driver confirmed arrival at the pickup branch.',
    )) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverBranchPickupVerificationScreen(
          config: widget.config,
          route: route,
          repository: widget.pickupRepository,
          criticalActionGate: widget.criticalActionGate,
          onPickupReceived: (receipt) {
            _advanceTimeline(
              DriverDeliveryState.pickedUp,
              source: 'branch_pickup',
              note: 'Branch verification completed and custody transferred.',
            );
            if (mounted) {
              setState(() => _pickupReceivedLocally = true);
            }
            widget.onPickupReceived?.call(receipt);
          },
        ),
      ),
    );
  }

  void _openStartDelivery() {
    final route = _route;
    if (route == null) return;

    final activeDelivery = DriverActiveDeliverySummary(
      orderNumber: widget.delivery.orderNumber,
      status: 'Picked up',
      pickupBranch: widget.delivery.pickupBranch,
      destinationArea: widget.delivery.destinationArea,
      etaMinutes: widget.delivery.etaMinutes,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverStartDeliveryScreen(
          config: widget.config,
          delivery: activeDelivery,
          route: route,
          repository: widget.startDeliveryRepository,
          onDeliveryStarted: (receipt) {
            _advanceTimeline(
              DriverDeliveryState.outForDelivery,
              source: 'start_delivery',
              note: 'Driver explicitly started delivery to the customer.',
            );
            if (mounted) {
              setState(() => _deliveryStartedLocally = true);
            }
            widget.onDeliveryStarted?.call(receipt);
          },
        ),
      ),
    );
  }

  void _openOrderContents() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverOrderContentsScreen(
          config: widget.config,
          orderNumber: widget.delivery.orderNumber,
          repository: widget.orderContentsRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Route to Branch'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _route == null) {
      return const AppLoadingState(label: 'Loading pickup route…');
    }

    if (_route == null) {
      return AppStateView.error(
        title: 'Route unavailable',
        message: _errorMessage ??
            'Getin could not confirm the branch route for this delivery.',
        onRetry: _load,
      );
    }

    final route = _route!;
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
              _BranchHero(
                  route: route,
                  isDemo:
                      _repository.source == DriverBranchRouteDataSource.demo),
              const SizedBox(height: 14),
              _PickupSummary(route: route, state: _timeline.currentState),
              const SizedBox(height: 14),
              _RouteMapPreview(route: route),
              const SizedBox(height: 14),
              DriverNavigationCard(
                target: DriverNavigationTarget(
                  label: route.branchName,
                  address: route.branchAddress,
                  latitude: route.branchCoordinates.latitude,
                  longitude: route.branchCoordinates.longitude,
                ),
                launcher: widget.navigationLauncher,
                preferenceStore: widget.navigationPreferenceStore,
              ),
              const SizedBox(height: 14),
              _RouteMetrics(route: route),
              const SizedBox(height: 14),
              DriverActiveDeliveryTimelineCard(timeline: _timeline),
              const SizedBox(height: 14),
              _BranchActions(
                onCallBranch: _callBranch,
                onSupport: _openSupport,
              ),
              const SizedBox(height: 14),
              _PickupInstructions(instructions: route.pickupInstructions),
              const SizedBox(height: 14),
              _OrderContentsEntry(onOpen: _openOrderContents),
              const SizedBox(height: 14),
              _BranchArrivalAction(
                alreadyPickedUp: _pickupReceivedLocally ||
                    _timeline.currentState == DriverDeliveryState.pickedUp ||
                    _timeline.currentState ==
                        DriverDeliveryState.outForDelivery,
                deliveryStarted: _deliveryStartedLocally ||
                    _timeline.currentState ==
                        DriverDeliveryState.outForDelivery,
                onArrived: _openPickupVerification,
                onStartDelivery: _openStartDelivery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchHero extends StatelessWidget {
  final DriverBranchRouteInfo route;
  final bool isDemo;

  const _BranchHero({required this.route, required this.isDemo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: Responsive.isCompact(context) ? 190 : 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              route.branchImageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.green,
                child: Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.beige,
                    size: 58,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x16000000), Color(0xCC0D211C)],
                  stops: [0.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDemo) ...[
                    const StatusPill(
                        label: 'DEMO ROUTE', tone: StatusTone.warning),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    route.branchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    route.branchAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFEDE9DF),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupSummary extends StatelessWidget {
  final DriverBranchRouteInfo route;
  final DriverDeliveryState state;

  const _PickupSummary({required this.route, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.orderNumber,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const StatusPill(label: 'ACTIVE', tone: StatusTone.success),
        ],
      ),
    );
  }
}

class _RouteMapPreview extends StatelessWidget {
  final DriverBranchRouteInfo route;

  const _RouteMapPreview({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFECE8DE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
              child: CustomPaint(painter: _MiniRoutePainter())),
          const Positioned(
            left: 18,
            bottom: 20,
            child: _MapPin(
              icon: Icons.navigation_rounded,
              label: 'You',
              dark: true,
            ),
          ),
          Positioned(
            right: 18,
            top: 28,
            child: _MapPin(
              icon: Icons.storefront_rounded,
              label: route.branchName,
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(.94),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text(
                'MAP PREVIEW',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.greenDark.withOpacity(.88),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Open external navigation below',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  const _MiniRoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final secondaryRoad = Paint()
      ..color = const Color(0xFFD7D2C8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final backgroundLines = <Path>[
      Path()
        ..moveTo(-20, size.height * .35)
        ..quadraticBezierTo(
            size.width * .35, 0, size.width + 20, size.height * .25),
      Path()
        ..moveTo(-30, size.height * .78)
        ..quadraticBezierTo(size.width * .42, size.height * .55,
            size.width + 30, size.height * .86),
      Path()
        ..moveTo(size.width * .28, -20)
        ..quadraticBezierTo(size.width * .55, size.height * .45,
            size.width * .42, size.height + 20),
    ];

    for (final path in backgroundLines) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, secondaryRoad);
    }

    final routePath = Path()
      ..moveTo(size.width * .19, size.height * .78)
      ..cubicTo(
        size.width * .38,
        size.height * .68,
        size.width * .53,
        size.height * .48,
        size.width * .73,
        size.height * .32,
      );
    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;

  const _MapPin({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? AppColors.greenDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 3),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: dark ? AppColors.beige : AppColors.green,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark ? AppColors.white : AppColors.greenDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMetrics extends StatelessWidget {
  final DriverBranchRouteInfo route;

  const _RouteMetrics({required this.route});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.schedule_rounded,
            label: 'ETA',
            value: '${route.etaMinutes} min',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: '${route.distanceKm.toStringAsFixed(1)} km',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.green, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

class _BranchActions extends StatelessWidget {
  final VoidCallback onCallBranch;
  final VoidCallback onSupport;

  const _BranchActions({
    required this.onCallBranch,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 350) {
          return Column(
            children: [
              GetinActionButton(
                label: 'Call Branch',
                icon: Icons.call_outlined,
                onPressed: onCallBranch,
              ),
              const SizedBox(height: 10),
              GetinActionButton(
                label: 'Support',
                icon: Icons.support_agent_rounded,
                secondary: true,
                onPressed: onSupport,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: GetinActionButton(
                label: 'Call Branch',
                icon: Icons.call_outlined,
                onPressed: onCallBranch,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GetinActionButton(
                label: 'Support',
                icon: Icons.support_agent_rounded,
                secondary: true,
                onPressed: onSupport,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PickupInstructions extends StatelessWidget {
  final List<String> instructions;

  const _PickupInstructions({required this.instructions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_outlined, color: AppColors.green, size: 21),
              SizedBox(width: 9),
              Text(
                'Pickup instructions',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            instructions.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == instructions.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(.35),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      instructions[index],
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
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

class _OrderContentsEntry extends StatelessWidget {
  final VoidCallback onOpen;

  const _OrderContentsEntry({required this.onOpen});

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
          Text(
            'Order Contents',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Review bag count, item count, handling instructions and delivery-relevant notes before leaving the branch.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          GetinActionButton(
            label: 'View Order Contents',
            icon: Icons.inventory_2_outlined,
            secondary: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _BranchArrivalAction extends StatelessWidget {
  final bool alreadyPickedUp;
  final bool deliveryStarted;
  final VoidCallback onArrived;
  final VoidCallback onStartDelivery;

  const _BranchArrivalAction({
    required this.alreadyPickedUp,
    required this.deliveryStarted,
    required this.onArrived,
    required this.onStartDelivery,
  });

  @override
  Widget build(BuildContext context) {
    if (deliveryStarted) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4EF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBDD6CA)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.route_rounded, color: AppColors.success, size: 21),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Delivery has started. Return to the Driver app and resume the active delivery to open destination navigation.',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (alreadyPickedUp) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success, size: 21),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Pickup complete',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Review Order Contents, secure the bags, then explicitly start the delivery before leaving the branch.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 13),
            GetinActionButton(
              label: 'Start Delivery',
              icon: Icons.route_rounded,
              onPressed: onStartDelivery,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.store_mall_directory_outlined,
                  color: AppColors.green, size: 22),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'At the branch?',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Start branch verification before taking custody of the order.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          GetinActionButton(
            label: 'Arrived at Branch • Verify Pickup',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: onArrived,
          ),
        ],
      ),
    );
  }
}
