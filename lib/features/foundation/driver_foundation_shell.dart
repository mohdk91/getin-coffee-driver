import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/data/driver_api_context.dart';
import '../../core/navigation/driver_navigation_push_guard.dart';
import '../../core/navigation/driver_tab.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/uat/driver_uat_completed_delivery_store.dart';
import '../../core/uat/driver_uat_pin_lockout_store.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/driver_app_scaffold.dart';
import '../active_delivery/domain/driver_delivery_state_machine.dart';
import '../availability/data/driver_availability_repository.dart';
import '../background_location/data/driver_background_location_controller.dart';
import '../background_location/domain/driver_background_location_models.dart';
import '../delivery/data/driver_start_delivery_repository.dart';
import '../delivery/domain/driver_start_delivery_models.dart';
import '../delivery_completion/data/driver_delivery_completion_repository.dart';
import '../delivery_completion/domain/driver_delivery_completion_models.dart';
import '../delivery_exceptions/data/driver_delivery_exception_repository.dart';
import '../delivery_exceptions/domain/driver_delivery_exception_models.dart';
import '../earnings/driver_earnings_screen.dart';
import '../eligibility/data/driver_order_eligibility_repository.dart';
import '../eligibility/domain/driver_order_eligibility_models.dart';
import '../eligibility/driver_order_eligibility_screen.dart';
import '../home/data/driver_home_repository.dart';
import '../home/domain/driver_home_models.dart';
import '../home/driver_home_dashboard.dart';
import '../incoming_orders/driver_incoming_order_capacity.dart';
import '../incoming_orders/driver_incoming_order_offer_dialog.dart';
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
import '../recovery/data/driver_runtime_recovery_api_repository.dart';
import '../support/data/driver_support_chat_repository.dart';
import '../support/driver_support_chat_screen.dart';

class DriverFoundationShell extends StatefulWidget {
  final AppConfig config;
  final DriverHomeRepository? homeRepository;
  final DriverAvailabilityRepository? availabilityRepository;
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
    this.homeRepository,
    this.availabilityRepository,
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
  bool _incomingOfferVisible = false;
  int _homeReloadToken = 0;
  final DriverNavigationPushGuard _navigationPushGuard =
      DriverNavigationPushGuard();
  final DriverUatCompletedDeliveryStore _uatCompletedDeliveryStore =
      const SharedPreferencesDriverUatCompletedDeliveryStore();
  final DriverUatPinLockoutStore _uatPinLockoutStore =
      SharedPreferencesDriverUatPinLockoutStore();

  late final DriverRuntimeRecoveryStore _recoveryStore =
      widget.recoveryStore ?? SharedPreferencesDriverRuntimeRecoveryStore();

  late final DriverHomeRepository _homeRepository = widget.homeRepository ??
      DriverHomeRepositoryFactory.create(widget.config);
  late final DriverAvailabilityRepository _availabilityRepository =
      widget.availabilityRepository ??
          DriverAvailabilityRepositoryFactory.create(widget.config);

  late final bool _ownsBackgroundLocationController =
      widget.backgroundLocationController == null;
  late final DriverBackgroundLocationController _backgroundLocationController =
      widget.backgroundLocationController ??
          DriverBackgroundLocationControllerFactory.create(widget.config);

  late final DriverLocationRepository _locationRepository =
      widget.locationRepository ??
          DriverLocationRepositoryFactory.create(widget.config);
  late final DriverOrderEligibilityRepository _eligibilityRepository =
      widget.eligibilityRepository ??
          DriverOrderEligibilityRepositoryFactory.create(widget.config);
  late final DriverOrderAcceptanceRepository _acceptanceRepository =
      widget.acceptanceRepository ??
          DriverOrderAcceptanceRepositoryFactory.create(widget.config);
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
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
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

  bool _retainsOperationalHold(DriverDeliveryState state) =>
      state == DriverDeliveryState.failedDelivery ||
      state == DriverDeliveryState.returnedToBranch;

  bool _shouldPersistActiveDelivery(DriverActiveDeliverySummary delivery) =>
      !delivery.resolvedState.isTerminal ||
      _retainsOperationalHold(delivery.resolvedState);

  Future<void> _restoreRuntimeState() async {
    DriverRuntimeRecoverySnapshot recovered;
    try {
      recovered = await _recoveryStore.load();
    } catch (_) {
      recovered = DriverRuntimeRecoverySnapshot.empty;
    }
    if (!widget.config.allowsDemo && widget.config.isApiConfigured) {
      try {
        recovered = await DriverRuntimeRecoveryApiRepository(
          DriverApiContext.create(widget.config),
        ).load();
      } catch (_) {
        // Offline startup may use the last local snapshot. Critical mutations
        // remain protected by the app's online action gate.
      }
    }
    if (!mounted) {
      return;
    }

    final recoveredDelivery = recovered.activeDelivery;
    final canRestoreDelivery = recoveredDelivery != null &&
        _shouldPersistActiveDelivery(recoveredDelivery) &&
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
    if (!_runtimeRecoveryLoaded) {
      return;
    }
    final active = _currentActiveDelivery;
    unawaited(
      _recoveryStore.save(
        DriverRuntimeRecoverySnapshot(
          activeDelivery: active != null && _shouldPersistActiveDelivery(active)
              ? active
              : null,
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
    if (snapshot == null) {
      return;
    }

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
    if (_offlineRetrying) {
      return;
    }
    setState(() {
      _offlineRetrying = true;
      _homeReloadToken += 1;
    });
  }

  void _handleHomeLoadFinished() {
    if (!mounted || !_offlineRetrying) {
      return;
    }
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
    if (!mounted || current == null) {
      return false;
    }

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
    if (!mounted) {
      return;
    }

    var nextSnapshot = snapshot;
    final incoming = snapshot.activeDelivery;
    final recoveredLocal = _locallyAcceptedDelivery;
    final preserveRecoveredDemo = widget.config.allowsDemo &&
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

  DriverIncomingOrderCapacity get _incomingOrderCapacity =>
      DriverIncomingOrderCapacity(
        activeOrderCount: _hasRunningActiveDelivery ? 1 : 0,
      );

  Future<void> _openIncomingOrderUatMenu() async {
    if (!widget.config.uatDemoEnabled || _incomingOfferVisible) {
      return;
    }

    final scenario = await showModalBottomSheet<_IncomingOrderUatScenario>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Incoming order UAT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Local-only scenarios. Nothing here creates or changes a production order.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Idle driver • broadcast offer'),
                    subtitle: const Text(
                      'Reset local UAT delivery state, then receive and accept a new offer.',
                    ),
                    onTap: () => Navigator.of(context).pop(
                      _IncomingOrderUatScenario.idleBroadcast,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block_rounded),
                    title: const Text('Active delivery • offer blocked'),
                    subtitle: const Text(
                      'Seed one active delivery and confirm another broadcast is blocked.',
                    ),
                    onTap: () => Navigator.of(context).pop(
                      _IncomingOrderUatScenario.activeDeliveryBlocked,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups_2_outlined),
                    title: const Text('Broadcast race'),
                    subtitle: const Text(
                      'Another demo driver already owns the order; acceptance must fail safely.',
                    ),
                    onTap: () => Navigator.of(context).pop(
                      _IncomingOrderUatScenario.alreadyTaken,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Offer expiry'),
                    subtitle: const Text(
                      'Reset to idle and run an eight-second visual expiry test.',
                    ),
                    onTap: () => Navigator.of(context).pop(
                      _IncomingOrderUatScenario.expires,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: const Text('Reset completed demo history'),
                    subtitle: const Text(
                      'Clear only locally persisted UAT completions and dashboard stats.',
                    ),
                    onTap: () => Navigator.of(context).pop(
                      _IncomingOrderUatScenario.resetCompletedHistory,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || scenario == null) {
      return;
    }

    if (scenario == _IncomingOrderUatScenario.resetCompletedHistory) {
      await _resetIncomingOrderUatCompletedHistory();
      return;
    }

    if (scenario == _IncomingOrderUatScenario.activeDeliveryBlocked) {
      await _prepareIncomingOrderUatActiveDriver();
    } else {
      await _prepareIncomingOrderUatIdleDriver();
    }
    if (!mounted) return;
    await _showIncomingOrderUatScenario(scenario);
  }

  Future<void> _resetIncomingOrderUatCompletedHistory() async {
    if (!widget.config.uatDemoEnabled || !mounted) return;

    await _uatCompletedDeliveryStore.clear();
    if (!mounted) return;

    setState(() {
      _lastCompletedDelivery = null;
      _homeReloadToken += 1;
    });
    _showIncomingOrderMessage(
      'Local UAT completed history and dashboard stats were reset.',
    );
  }

  Future<void> _prepareIncomingOrderUatIdleDriver() async {
    if (!widget.config.uatDemoEnabled || !mounted) return;

    // Starting a fresh UAT delivery is the explicit test-lab reset boundary.
    // A PIN lockout must survive reload/reopen/restart for the current order,
    // but a brand-new local UAT scenario needs clean verification state.
    await _uatPinLockoutStore.clearAll();
    await DemoDriverDeliveryExceptionRepository.clearPersistedDemoState();
    if (!mounted) return;

    setState(() {
      _locallyAcceptedDelivery = null;
      _activeTimeline = null;
      _completedOrderNumber = null;
      final snapshot = _homeSnapshot;
      if (snapshot != null) {
        _homeSnapshot = snapshot.copyWith(
          clearActiveDelivery: true,
          updatedAt: DateTime.now(),
        );
      }
      _homeReloadToken += 1;
    });
    _syncBackgroundLocation();

    if (_runtimeRecoveryLoaded) {
      await _recoveryStore.save(
        DriverRuntimeRecoverySnapshot(
          activeDelivery: null,
          completedOrderNumber: null,
          lastSuccessfulSyncAt: _lastSuccessfulSyncAt,
        ),
      );
    }
  }

  Future<void> _prepareIncomingOrderUatActiveDriver() async {
    if (!widget.config.uatDemoEnabled || !mounted) return;

    const active = DriverActiveDeliverySummary(
      orderNumber: 'GD-UAT-ACTIVE',
      status: 'Going to branch • Demo',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 8,
      state: DriverDeliveryState.goingToBranch,
    );
    final timeline = DriverDeliveryStateMachine.seed(
      orderNumber: active.orderNumber,
      currentState: DriverDeliveryState.goingToBranch,
      source: 'uat_active_capacity',
    );

    setState(() {
      _completedOrderNumber = null;
      _locallyAcceptedDelivery = active;
      _activeTimeline = timeline;
      final snapshot = _homeSnapshot;
      if (snapshot != null) {
        _homeSnapshot = snapshot.copyWith(
          activeDelivery: active,
          availableOrders: 0,
          updatedAt: DateTime.now(),
        );
      }
      _homeReloadToken += 1;
    });
    _syncBackgroundLocation();

    if (_runtimeRecoveryLoaded) {
      await _recoveryStore.save(
        DriverRuntimeRecoverySnapshot(
          activeDelivery: active,
          completedOrderNumber: null,
          lastSuccessfulSyncAt: _lastSuccessfulSyncAt,
        ),
      );
    }
  }

  DriverOrderCandidate _incomingOrderUatCandidate(
    _IncomingOrderUatScenario scenario,
  ) {
    final alreadyTaken = scenario == _IncomingOrderUatScenario.alreadyTaken;
    final orderNumber = switch (scenario) {
      _IncomingOrderUatScenario.alreadyTaken => 'GD-3102',
      _IncomingOrderUatScenario.expires => 'GD-UAT-9003',
      _ => 'GD-UAT-9001',
    };
    return DriverOrderCandidate(
      orderNumber: orderNumber,
      pickupBranch: 'Stanley',
      region: 'East Alexandria',
      zone: 'San Stefano',
      destinationArea: alreadyTaken ? 'Gleem' : 'San Stefano',
      distanceToBranchKm: 1.8,
      deliveryDistanceKm: 4.6,
      estimatedDurationMinutes: 19,
      bagCount: 2,
      estimatedDriverEarning: 72,
      currencyCode: 'EGP',
      allowedVehicleTypes: const <String>['motorcycle', 'car'],
      isAvailable: true,
    );
  }

  Future<void> _showIncomingOrderUatScenario(
    _IncomingOrderUatScenario scenario,
  ) async {
    if (!mounted || _incomingOfferVisible) {
      return;
    }

    final initialCapacity = _incomingOrderCapacity;
    if (!initialCapacity.canReceiveOffer) {
      await _showIncomingOrderCapacityBlockedDialog(initialCapacity);
      return;
    }

    final order = _incomingOrderUatCandidate(scenario);
    setState(() => _incomingOfferVisible = true);

    final decision = await showDriverIncomingOrderOfferDialog(
      context: context,
      order: order,
      offerDuration: scenario == _IncomingOrderUatScenario.expires
          ? const Duration(seconds: 8)
          : const Duration(seconds: 25),
      uatDemo: true,
    );

    if (!mounted) return;
    setState(() => _incomingOfferVisible = false);

    if (decision == null) {
      return;
    }

    if (decision == DriverIncomingOfferDecision.decline) {
      _showIncomingOrderMessage(
        'Demo offer declined. No production data was changed.',
      );
      return;
    }

    if (decision == DriverIncomingOfferDecision.expired) {
      _showIncomingOrderMessage(
        'Demo offer expired. It was not assigned to this driver.',
      );
      return;
    }

    final acceptanceCapacity = _incomingOrderCapacity;
    if (!acceptanceCapacity.canReceiveOffer) {
      _showIncomingOrderMessage(acceptanceCapacity.blockedMessage);
      return;
    }

    if (!driverCriticalActionAllowed(_criticalActionGate)) {
      _showIncomingOrderMessage(
        DriverCriticalAction.acceptOrder.offlineMessage,
      );
      return;
    }

    final result = await _acceptanceRepository.accept(
      order: order,
      driverId: 'demo-driver-001',
    );
    if (!mounted) return;

    if (result.isAccepted) {
      _handleOrderAccepted(DriverAcceptedOrder(order: order, result: result));
    }
    _showIncomingOrderMessage(result.message);
  }

  Future<void> _showIncomingOrderCapacityBlockedDialog(
    DriverIncomingOrderCapacity capacity,
  ) async {
    if (!mounted) return;
    final active = _currentActiveDelivery;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.block_rounded),
        title: const Text('New order blocked'),
        content: Text(
          active == null
              ? capacity.blockedMessage
              : '${active.orderNumber} is already in progress. ${capacity.blockedMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showIncomingOrderMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  void _handleOrderAccepted(DriverAcceptedOrder acceptedOrder) {
    if (!mounted) {
      return;
    }

    // Acceptance is a task handoff, not just a list-state change. Dismiss any
    // keyboard/focus left behind by the Orders UI before entering the route.
    FocusManager.instance.primaryFocus?.unfocus();

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
    if (routing.isSuccess) {
      timeline = routing.timeline;
    }

    setState(() {
      _activeTimeline = timeline;
      _locallyAcceptedDelivery = DriverActiveDeliverySummary(
        apiOrderId: acceptedOrder.order.apiOrderId,
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

    // Acceptance happens from an interaction callback after any offer dialog
    // has already been popped. The state above is synchronously available, so
    // hand off immediately instead of relying on a later frame callback. This
    // keeps the accepted-order route deterministic in both UAT and production.
    _openActiveDelivery();
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
    final transitioned = _transitionActiveDelivery(
      DriverDeliveryState.outForDelivery,
      source: 'start_delivery',
      demo: receipt.isDemo,
      note: 'Driver explicitly started customer delivery.',
    );
    if (!transitioned || !mounted) return;

    // Start Delivery is a workflow handoff. Replace the confirmation screen
    // immediately with the customer destination flow so the driver does not
    // have to back out and manually resume the same active order.
    _openCustomerDelivery(replaceCurrent: true);
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

  Future<void> _persistUatCompletedDelivery(
    DriverDeliveryCompletionReceipt receipt,
    DriverActiveDeliverySummary delivery,
  ) async {
    if (!widget.config.uatDemoEnabled || !receipt.isDemo) return;

    final uatOffer = _incomingOrderUatCandidate(
      _IncomingOrderUatScenario.idleBroadcast,
    );
    final matchesPrimaryUatOffer =
        uatOffer.orderNumber.toUpperCase() == receipt.orderNumber.toUpperCase();

    await _uatCompletedDeliveryStore.upsert(
      DriverUatCompletedDeliveryRecord(
        orderNumber: receipt.orderNumber,
        pickupBranch: delivery.pickupBranch,
        destinationArea: delivery.destinationArea,
        completedAt: receipt.completedAt,
        bagCount: matchesPrimaryUatOffer ? uatOffer.bagCount : 0,
        driverEarning:
            matchesPrimaryUatOffer ? uatOffer.estimatedDriverEarning : 0,
        currencyCode: matchesPrimaryUatOffer ? uatOffer.currencyCode : 'EGP',
      ),
    );

    if (!mounted) return;
    setState(() => _homeReloadToken += 1);
  }

  void _handleDeliveryCompleted(DriverDeliveryCompletionReceipt receipt) {
    if (!mounted) {
      return;
    }

    final transitioned = _transitionActiveDelivery(
      DriverDeliveryState.delivered,
      source: 'delivery_completion',
      demo: receipt.isDemo,
      note: 'Customer handoff verified and completion confirmed.',
    );
    if (!transitioned) {
      return;
    }

    final completedDelivery = _currentActiveDelivery;
    if (completedDelivery != null) {
      unawaited(_persistUatCompletedDelivery(receipt, completedDelivery));
    }
    setState(() {
      _completedOrderNumber = receipt.orderNumber;
      _lastCompletedDelivery = completedDelivery;
      _locallyAcceptedDelivery = null;
      _activeTimeline = null;
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

  void _returnHomeAfterDeliveryCompletion() {
    if (!mounted) return;

    setState(() => _tab = DriverTab.home);

    // The delivery flow can contain Route to Branch, Start Delivery, customer
    // destination, PIN/QR verification and completion routes. Pop every route
    // above the Foundation shell itself so a completed order can never reveal
    // a stale pickup/delivery screen underneath the receipt.
    final shellRoute = ModalRoute.of(context);
    if (shellRoute == null) return;
    Navigator.of(context).popUntil((route) => identical(route, shellRoute));
  }

  Widget _buildCustomerDeliveryScreen(
    DriverActiveDeliverySummary delivery,
    DriverDeliveryTimeline timeline,
  ) {
    return DriverDeliveryNavigationScreen(
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
      onReturnHome: _returnHomeAfterDeliveryCompletion,
      criticalActionGate: _criticalActionGate,
    );
  }

  void _openCustomerDelivery({bool replaceCurrent = false}) {
    final rawDelivery = _currentActiveDelivery;
    final delivery =
        rawDelivery?.orderNumber == _completedOrderNumber ? null : rawDelivery;
    if (delivery == null) return;

    final timeline = _ensureTimeline(delivery);
    final route = MaterialPageRoute<void>(
      builder: (_) => _buildCustomerDeliveryScreen(delivery, timeline),
    );

    if (replaceCurrent) {
      unawaited(Navigator.of(context).pushReplacement<void, void>(route));
      return;
    }

    _pushOnce(
      'customer:${delivery.orderNumber}',
      (_) => _buildCustomerDeliveryScreen(delivery, timeline),
    );
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

    if (destinationFlow) {
      _openCustomerDelivery();
      return;
    }

    _pushOnce(
      'active:${delivery.orderNumber}',
      (_) => DriverRouteToBranchScreen(
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
    if (!mounted) {
      return;
    }
    final snapshot = _homeSnapshot;
    if (snapshot == null || snapshot.unreadNotifications == count) {
      return;
    }
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
    if (!mounted) {
      return;
    }
    final snapshot = _homeSnapshot;
    if (snapshot == null || snapshot.gpsState == state) {
      return;
    }

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
    if (snapshot == null) {
      return;
    }

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
        activeDeliveryOverride: activeDelivery,
        repository: _homeRepository,
        availabilityRepository: _availabilityRepository,
        eligibilityRepository: _eligibilityRepository,
        onSnapshotChanged: _receiveHomeSnapshot,
        onResumeActiveDelivery: _openActiveDelivery,
        onOpenGpsServiceRegion: _openGpsServiceRegion,
        onOpenOrderEligibility: _openOrderEligibility,
        onOpenRatingsReviews: _openRatingsReviews,
        onOpenOrders: () => setState(() => _tab = DriverTab.orders),
        onOpenEarnings: () => setState(() => _tab = DriverTab.earnings),
        onOpenSupport: () => _openSupport(delivery: activeDelivery),
        reloadToken: _homeReloadToken,
        onLoadFinished: _handleHomeLoadFinished,
      ),
      if (_homeSnapshot == null)
        const AppLoadingState(label: 'Loading orders…')
      else
        DriverOrderHistoryScreen(
          key: ValueKey<String>('orders-history-$_homeReloadToken'),
          config: widget.config,
          eligibilityRepository: _eligibilityRepository,
          availability: _homeSnapshot!.availability,
          activeDelivery: activeDelivery,
          driverApproved: true,
          acceptanceRepository: _acceptanceRepository,
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
      onUatIncomingOrder:
          widget.config.uatDemoEnabled ? _openIncomingOrderUatMenu : null,
      body: IndexedStack(index: _tab.index, children: pages),
    );
  }
}

enum _IncomingOrderUatScenario {
  idleBroadcast,
  activeDeliveryBlocked,
  alreadyTaken,
  expires,
  resetCompletedHistory,
}
