import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_environment.dart';
import '../../core/navigation/driver_navigation_push_guard.dart';
import '../../core/navigation/driver_tab.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/driver_app_scaffold.dart';
import '../active_delivery/domain/driver_delivery_state_machine.dart';
import '../background_location/data/driver_background_location_controller.dart';
import '../background_location/domain/driver_background_location_models.dart';
import '../delivery/data/driver_start_delivery_repository.dart';
import '../delivery/domain/driver_start_delivery_models.dart';
import '../delivery_completion/data/driver_delivery_completion_repository.dart';
import '../delivery_completion/domain/driver_delivery_completion_models.dart';
import '../delivery_exceptions/domain/driver_delivery_exception_models.dart';
import '../earnings/driver_earnings_screen.dart';
import '../eligibility/data/driver_order_eligibility_repository.dart';
import '../eligibility/driver_order_eligibility_screen.dart';
import '../home/data/driver_home_repository.dart';
import '../home/domain/driver_home_models.dart';
import '../home/driver_home_dashboard.dart';
import '../location/data/driver_location_repository.dart';
import '../location/driver_location_service_region_screen.dart';
import '../navigation/data/driver_navigation_launcher.dart';
import '../navigation/data/driver_navigation_preference_store.dart';
import '../navigation/driver_delivery_navigation_screen.dart';
import '../notifications/data/driver_notifications_repository.dart';
import '../notifications/driver_notifications_screen.dart';
import '../orders/data/driver_order_acceptance_repository.dart';
import '../orders/domain/driver_order_acceptance_models.dart';
import '../order_history/driver_order_history_screen.dart';
import '../pickup/data/driver_branch_pickup_repository.dart';
import '../pickup/domain/driver_branch_pickup_models.dart';
import '../profile/data/driver_profile_repository.dart';
import '../profile/driver_profile_screen.dart';
import '../route/data/driver_branch_route_repository.dart';
import '../route/driver_route_to_branch_screen.dart';
import '../ratings/domain/driver_rating_models.dart';
import '../ratings/driver_ratings_reviews_screen.dart';
import '../recovery/data/driver_runtime_recovery_store.dart';
import '../support/data/driver_support_chat_repository.dart';
import '../support/driver_support_chat_screen.dart';

class DriverFoundationShell extends StatefulWidget {
  final AppConfig config;
  final DriverHomeRepository homeRepository;
  final DriverLocationRepository? locationRepository;
  final DriverOrderEligibilityRepository? eligibilityRepository;
  final DriverOrderAcceptanceRepository? acceptanceRepository;
  final DriverBranchRouteRepository? routeRepository;
  final DriverBranchPickupRepository? pickupRepository;
  final DriverStartDeliveryRepository? startDeliveryRepository;
  final DriverDeliveryCompletionRepository? completionRepository;
  final DriverNavigationLauncher? navigationLauncher;
  final DriverNavigationPreferenceStore? navigationPreferenceStore;
  final DriverNotificationsRepository? notificationsRepository;
  final DriverSupportChatRepository? supportRepository;
  final DriverProfileRepository? profileRepository;
  final DriverBackgroundLocationController? backgroundLocationController;
  final DriverRuntimeRecoveryStore? recoveryStore;

  const DriverFoundationShell({
    super.key,
    required this.config,
    this.homeRepository = const DemoDriverHomeRepository(),
    this.locationRepository,
    this.eligibilityRepository,
    this.acceptanceRepository,
    this.routeRepository,
    this.pickupRepository,
    this.startDeliveryRepository,
    this.completionRepository,
    this.navigationLauncher,
    this.navigationPreferenceStore,
    this.notificationsRepository,
    this.supportRepository,
    this.profileRepository,
    this.backgroundLocationController,
    this.recoveryStore,
  });

  @override
  State<DriverFoundationShell> createState() => _DriverFoundationShellState();
}

class _DriverFoundationShellState extends State<DriverFoundationShell>
    with WidgetsBindingObserver {
  DriverTab _tab = DriverTab.home;
  DriverHomeSnapshot? _homeSnapshot;
  DriverActiveDeliverySummary? _locallyAcceptedDelivery;
  DriverDeliveryTimeline? _activeTimeline;
  String? _completedOrderNumber;
  DriverActiveDeliverySummary? _lastCompletedDelivery;
  DateTime? _lastSuccessfulSyncAt;
  bool _offlineRetrying = false;
  bool _runtimeRecoveryLoaded = false;
  int _homeReloadToken = 0;
  final DriverNavigationPushGuard _navigationPushGuard =
      DriverNavigationPushGuard();

  late final DriverRuntimeRecoveryStore _recoveryStore =
      widget.recoveryStore ?? SharedPreferencesDriverRuntimeRecoveryStore();

  late final bool _ownsBackgroundLocationController =
      widget.backgroundLocationController == null;
  late final DriverBackgroundLocationController _backgroundLocationController =
      widget.backgroundLocationController ??
          DriverBackgroundLocationControllerFactory.create(widget.config);

  late final DriverLocationRepository _locationRepository =
      widget.locationRepository ??
          (widget.config.environment == AppEnvironment.development
              ? const DemoDriverLocationRepository()
              : const UnavailableDriverLocationRepository());
  late final DriverOrderEligibilityRepository _eligibilityRepository =
      widget.eligibilityRepository ??
          DriverOrderEligibilityRepositoryFactory.create(widget.config);
  late final DriverBranchRouteRepository _routeRepository =
      widget.routeRepository ??
          DriverBranchRouteRepositoryFactory.create(widget.config);
  late final DriverBranchPickupRepository _pickupRepository =
      widget.pickupRepository ??
          DriverBranchPickupRepositoryFactory.create(widget.config);
  late final DriverStartDeliveryRepository _startDeliveryRepository =
      widget.startDeliveryRepository ??
          DriverStartDeliveryRepositoryFactory.create(widget.config);
  late final DriverDeliveryCompletionRepository _completionRepository =
      widget.completionRepository ??
          DriverDeliveryCompletionRepositoryFactory.create(widget.config);
  late final DriverNotificationsRepository _notificationsRepository =
      widget.notificationsRepository ??
          DriverNotificationsRepositoryFactory.create(widget.config);
  late final DriverSupportChatRepository _supportRepository =
      widget.supportRepository ??
          DriverSupportChatRepositoryFactory.create(widget.config);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreRuntimeState());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() => _homeReloadToken += 1);
    _syncBackgroundLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsBackgroundLocationController) {
      _backgroundLocationController.dispose();
    }
    super.dispose();
  }

  DriverActiveDeliverySummary? get _currentActiveDelivery =>
      _locallyAcceptedDelivery ?? _homeSnapshot?.activeDelivery;

  Future<void> _restoreRuntimeState() async {
    DriverRuntimeRecoverySnapshot recovered;
    try {
      recovered = await _recoveryStore.load();
    } catch (_) {
      recovered = DriverRuntimeRecoverySnapshot.empty;
    }
    if (!mounted) return;

    final recoveredDelivery = recovered.activeDelivery;
    final canRestoreDelivery = recoveredDelivery != null &&
        !recoveredDelivery.resolvedState.isTerminal &&
        recoveredDelivery.orderNumber != recovered.completedOrderNumber;

    setState(() {
      _runtimeRecoveryLoaded = true;
      _completedOrderNumber = recovered.completedOrderNumber;
      _lastSuccessfulSyncAt = recovered.lastSuccessfulSyncAt;
      if (canRestoreDelivery) {
        _locallyAcceptedDelivery = recoveredDelivery;
        _activeTimeline = DriverDeliveryStateMachine.seed(
          orderNumber: recoveredDelivery.orderNumber,
          currentState: recoveredDelivery.resolvedState,
          source: 'app_restart_restore',
        );
      }
    });
    _syncBackgroundLocation();
    _persistRuntimeState();
  }

  void _persistRuntimeState() {
    if (!_runtimeRecoveryLoaded) return;
    final active = _currentActiveDelivery;
    unawaited(
      _recoveryStore.save(
        DriverRuntimeRecoverySnapshot(
          activeDelivery:
              active?.resolvedState.isTerminal == true ? null : active,
          completedOrderNumber: _completedOrderNumber,
          lastSuccessfulSyncAt: _lastSuccessfulSyncAt,
        ),
      ),
    );
  }

  void _pushOnce(String key, WidgetBuilder builder) {
    unawaited(
      _navigationPushGuard.run(
        key,
        () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: builder),
          );
        },
      ),
    );
  }

  bool get _hasRunningActiveDelivery {
    final delivery = _currentActiveDelivery;
    if (delivery == null || delivery.orderNumber == _completedOrderNumber) {
      return false;
    }
    return !delivery.resolvedState.isTerminal;
  }

  void _syncBackgroundLocation() {
    final snapshot = _homeSnapshot;
    if (snapshot == null) return;

    unawaited(
      _backgroundLocationController.updateContext(
        DriverBackgroundLocationContext(
          availability: snapshot.availability,
          hasActiveDelivery: _hasRunningActiveDelivery,
          internetConnected: snapshot.internetConnected,
          gpsState: snapshot.gpsState,
        ),
      ),
    );
  }

  bool get _isOffline => _homeSnapshot?.internetConnected == false;

  bool _criticalActionGate() => !_isOffline;

  void _retryOfflineConnection() {
    if (_offlineRetrying) return;
    setState(() {
      _offlineRetrying = true;
      _homeReloadToken += 1;
    });
  }

  void _handleHomeLoadFinished() {
    if (!mounted || !_offlineRetrying) return;
    setState(() => _offlineRetrying = false);
  }

  bool _statusIsDemo(String status) => status.contains('• Demo');

  String _statusForState(DriverDeliveryState state, {required bool demo}) {
    return demo ? '${state.label} • Demo' : state.label;
  }

  DriverDeliveryTimeline _ensureTimeline(DriverActiveDeliverySummary delivery) {
    final existing = _activeTimeline;
    if (existing != null && existing.orderNumber == delivery.orderNumber) {
      return existing;
    }

    final seeded = DriverDeliveryStateMachine.seed(
      orderNumber: delivery.orderNumber,
      currentState: delivery.resolvedState,
    );
    _activeTimeline = seeded;
    return seeded;
  }

  bool _transitionActiveDelivery(
    DriverDeliveryState target, {
    required String source,
    bool? demo,
    String? note,
  }) {
    final current = _currentActiveDelivery;
    if (!mounted || current == null) return false;

    final timeline = _ensureTimeline(current);
    final result = DriverDeliveryStateMachine.advanceTo(
      timeline: timeline,
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

    final useDemo = demo ?? _statusIsDemo(current.status);
    final updated = current.copyWith(
      status: _statusForState(target, demo: useDemo),
      state: target,
    );

    setState(() {
      _activeTimeline = result.timeline;
      if (_locallyAcceptedDelivery?.orderNumber == current.orderNumber) {
        _locallyAcceptedDelivery = updated;
      } else {
        final snapshot = _homeSnapshot;
        if (snapshot != null &&
            snapshot.activeDelivery?.orderNumber == current.orderNumber) {
          _homeSnapshot = snapshot.copyWith(
            activeDelivery: updated,
            updatedAt: DateTime.now(),
          );
        }
      }
    });
    _syncBackgroundLocation();
    _persistRuntimeState();
    return true;
  }

  void _receiveHomeSnapshot(DriverHomeSnapshot snapshot) {
    if (!mounted) return;

    var nextSnapshot = snapshot;
    final incoming = snapshot.activeDelivery;
    final recoveredLocal = _locallyAcceptedDelivery;
    final preserveRecoveredDemo =
        widget.config.environment == AppEnvironment.development &&
            recoveredLocal != null &&
            incoming != null &&
            incoming.orderNumber != recoveredLocal.orderNumber;

    if (!preserveRecoveredDemo &&
        incoming != null &&
        incoming.orderNumber != _completedOrderNumber) {
      final timeline = _ensureTimeline(incoming);
      if (timeline.orderNumber == incoming.orderNumber) {
        nextSnapshot = snapshot.copyWith(
          activeDelivery: incoming.copyWith(
            state: timeline.currentState,
            status: _statusForState(
              timeline.currentState,
              demo: _statusIsDemo(incoming.status),
            ),
          ),
        );
      }
    }

    setState(() {
      _homeSnapshot = nextSnapshot;
      if (nextSnapshot.internetConnected) {
        _lastSuccessfulSyncAt = nextSnapshot.updatedAt;
      }
    });
    _syncBackgroundLocation();
    _persistRuntimeState();
  }

  void _handleOrderAccepted(DriverAcceptedOrder acceptedOrder) {
    if (!mounted) return;

    var timeline = DriverDeliveryStateMachine.seed(
      orderNumber: acceptedOrder.order.orderNumber,
      currentState: DriverDeliveryState.accepted,
      source: 'order_acceptance',
    );
    final routing = DriverDeliveryStateMachine.transition(
      timeline: timeline,
      to: DriverDeliveryState.goingToBranch,
      source: 'route_to_branch',
      note: 'Accepted order entered the branch-routing stage.',
    );
    if (routing.isSuccess) timeline = routing.timeline;

    setState(() {
      _activeTimeline = timeline;
      _locallyAcceptedDelivery = DriverActiveDeliverySummary(
        orderNumber: acceptedOrder.order.orderNumber,
        status: DriverDeliveryState.goingToBranch.label,
        pickupBranch: acceptedOrder.order.pickupBranch,
        destinationArea: acceptedOrder.order.destinationArea,
        etaMinutes: acceptedOrder.order.estimatedDurationMinutes,
        state: DriverDeliveryState.goingToBranch,
      );
      _tab = DriverTab.orders;
    });
    _syncBackgroundLocation();
    _persistRuntimeState();
  }

  void _handlePickupReceived(DriverBranchPickupReceipt receipt) {
    _transitionActiveDelivery(
      DriverDeliveryState.pickedUp,
      source: 'branch_pickup',
      demo: receipt.isDemo,
      note: 'Branch custody verification completed.',
    );
  }

  void _handleDeliveryStarted(DriverStartDeliveryReceipt receipt) {
    _transitionActiveDelivery(
      DriverDeliveryState.outForDelivery,
      source: 'start_delivery',
      demo: receipt.isDemo,
      note: 'Driver explicitly started customer delivery.',
    );
  }

  void _handleDeliveryException(DriverDeliveryExceptionReceipt receipt) {
    final target =
        receipt.reason == DriverDeliveryExceptionReason.returnToBranch
            ? DriverDeliveryState.returnedToBranch
            : DriverDeliveryState.failedDelivery;
    _transitionActiveDelivery(
      target,
      source: 'delivery_exception',
      demo: receipt.isDemo,
      note: receipt.reason.label,
    );
  }

  void _handleDeliveryStateChanged(DriverDeliveryState state) {
    _transitionActiveDelivery(
      state,
      source: 'delivery_flow',
    );
  }

  void _handleDeliveryCompleted(DriverDeliveryCompletionReceipt receipt) {
    if (!mounted) return;

    final transitioned = _transitionActiveDelivery(
      DriverDeliveryState.delivered,
      source: 'delivery_completion',
      demo: receipt.isDemo,
      note: 'Customer handoff verified and completion confirmed.',
    );
    if (!transitioned) return;

    final completedDelivery = _currentActiveDelivery;
    setState(() {
      _completedOrderNumber = receipt.orderNumber;
      _lastCompletedDelivery = completedDelivery;
      _locallyAcceptedDelivery = null;
      final snapshot = _homeSnapshot;
      if (snapshot != null &&
          snapshot.activeDelivery?.orderNumber == receipt.orderNumber) {
        _homeSnapshot = snapshot.copyWith(
          clearActiveDelivery: true,
          completedToday: snapshot.completedToday + 1,
          updatedAt: DateTime.now(),
        );
      }
      _tab = DriverTab.home;
    });
    _syncBackgroundLocation();
    _persistRuntimeState();
  }

  void _openActiveDelivery() {
    final rawDelivery = _currentActiveDelivery;
    final delivery =
        rawDelivery?.orderNumber == _completedOrderNumber ? null : rawDelivery;
    if (delivery == null) {
      setState(() => _tab = DriverTab.orders);
      return;
    }

    final timeline = _ensureTimeline(delivery);
    final destinationFlow = timeline.currentState.usesDeliveryDestinationFlow;

    _pushOnce(
      'active:${delivery.orderNumber}',
      (_) => destinationFlow
          ? DriverDeliveryNavigationScreen(
              delivery: delivery,
              config: widget.config,
              timeline: timeline,
              launcher: widget.navigationLauncher,
              preferenceStore: widget.navigationPreferenceStore,
              completionRepository: _completionRepository,
              supportRepository: _supportRepository,
              onStateChanged: _handleDeliveryStateChanged,
              onDeliveryException: _handleDeliveryException,
              onDeliveryCompleted: _handleDeliveryCompleted,
              criticalActionGate: _criticalActionGate,
            )
          : DriverRouteToBranchScreen(
              config: widget.config,
              delivery: delivery,
              timeline: timeline,
              repository: _routeRepository,
              pickupRepository: _pickupRepository,
              startDeliveryRepository: _startDeliveryRepository,
              navigationLauncher: widget.navigationLauncher,
              navigationPreferenceStore: widget.navigationPreferenceStore,
              onSupport: _openRouteSupport,
              onStateChanged: _handleDeliveryStateChanged,
              onPickupReceived: _handlePickupReceived,
              onDeliveryStarted: _handleDeliveryStarted,
              criticalActionGate: _criticalActionGate,
            ),
    );
  }

  void _openRouteSupport() {
    _openSupport(delivery: _currentActiveDelivery);
  }

  void _openSupport({
    DriverActiveDeliverySummary? delivery,
    String? contextOrderNumber,
    String? initialDraft,
  }) {
    final orderKey = delivery?.orderNumber ?? contextOrderNumber ?? 'general';
    _pushOnce(
      'support:$orderKey',
      (_) => DriverSupportChatScreen(
        config: widget.config,
        delivery: delivery,
        contextOrderNumber: contextOrderNumber,
        initialDraft: initialDraft,
        repository: _supportRepository,
      ),
    );
  }

  void _openNotifications() {
    _pushOnce(
      'notifications',
      (_) => DriverNotificationsScreen(
        config: widget.config,
        repository: _notificationsRepository,
        onUnreadCountChanged: _updateUnreadNotificationCount,
      ),
    );
  }

  void _updateUnreadNotificationCount(int count) {
    if (!mounted) return;
    final snapshot = _homeSnapshot;
    if (snapshot == null || snapshot.unreadNotifications == count) return;
    setState(() {
      _homeSnapshot = snapshot.copyWith(
        unreadNotifications: count,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _openGpsServiceRegion() {
    _pushOnce(
      'gps-service-region',
      (_) => DriverLocationServiceRegionScreen(
        config: widget.config,
        repository: _locationRepository,
        backgroundLocationController: _backgroundLocationController,
        onGpsStateChanged: _updateGpsState,
      ),
    );
  }

  void _updateGpsState(DriverGpsState state) {
    if (!mounted) return;
    final snapshot = _homeSnapshot;
    if (snapshot == null || snapshot.gpsState == state) return;

    setState(() {
      _homeSnapshot = snapshot.copyWith(
        gpsState: state,
        updatedAt: DateTime.now(),
      );
    });
    _syncBackgroundLocation();
  }

  void _openOrderEligibility() {
    final snapshot = _homeSnapshot;
    if (snapshot == null) return;

    _pushOnce(
      'order-eligibility',
      (_) => DriverOrderEligibilityScreen(
        config: widget.config,
        repository: _eligibilityRepository,
        availability: snapshot.availability,
        activeOrderCount: (_currentActiveDelivery == null) ? 0 : 1,
        driverApproved: true,
      ),
    );
  }

  void _openRatingsReviews() {
    _pushOnce(
      'ratings-reviews',
      (_) => DriverRatingsReviewsScreen(
        config: widget.config,
        onReportReview: _reportReviewThroughSupport,
      ),
    );
  }

  void _reportReviewThroughSupport(DriverCustomerReview review) {
    _openSupport(
      contextOrderNumber: review.orderNumber,
      initialDraft:
          'I want to report/dispute the customer review for order ${review.orderNumber}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawActiveDelivery = _currentActiveDelivery;
    final activeDelivery =
        rawActiveDelivery?.orderNumber == _completedOrderNumber
            ? null
            : rawActiveDelivery;
    final pages = <Widget>[
      DriverHomeDashboard(
        key: ValueKey<String>(_completedOrderNumber ?? 'active-delivery'),
        config: widget.config,
        completedOrderNumber: _completedOrderNumber,
        unreadNotificationsOverride: _homeSnapshot?.unreadNotifications,
        repository: widget.homeRepository,
        eligibilityRepository: _eligibilityRepository,
        onSnapshotChanged: _receiveHomeSnapshot,
        onResumeActiveDelivery: _openActiveDelivery,
        onOpenGpsServiceRegion: _openGpsServiceRegion,
        onOpenOrderEligibility: _openOrderEligibility,
        onOpenRatingsReviews: _openRatingsReviews,
        reloadToken: _homeReloadToken,
        onLoadFinished: _handleHomeLoadFinished,
      ),
      if (_homeSnapshot == null)
        const AppLoadingState(label: 'Loading orders…')
      else
        DriverOrderHistoryScreen(
          config: widget.config,
          eligibilityRepository: _eligibilityRepository,
          availability: _homeSnapshot!.availability,
          activeDelivery: activeDelivery,
          driverApproved: true,
          acceptanceRepository: widget.acceptanceRepository,
          onOrderAccepted: _handleOrderAccepted,
          lastCompletedDelivery: _lastCompletedDelivery,
          criticalActionGate: _criticalActionGate,
        ),
      DriverEarningsScreen(config: widget.config),
      DriverProfileScreen(
        config: widget.config,
        repository: widget.profileRepository,
      ),
    ];

    return DriverAppScaffold(
      currentTab: _tab,
      onTabChanged: (tab) => setState(() => _tab = tab),
      onNotifications: _openNotifications,
      onSupport: () => _openSupport(delivery: activeDelivery),
      hasUnreadNotifications: _homeSnapshot?.hasUnreadNotifications ?? false,
      activeOrderNumber: activeDelivery?.orderNumber,
      activeDeliveryStatus: activeDelivery?.status,
      onActiveDelivery: activeDelivery == null ? null : _openActiveDelivery,
      offline: _isOffline,
      lastSuccessfulSyncAt: _lastSuccessfulSyncAt,
      retryingConnection: _offlineRetrying,
      onRetryConnection: _retryOfflineConnection,
      body: IndexedStack(index: _tab.index, children: pages),
    );
  }
}
