import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_environment.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import '../active_delivery/domain/driver_delivery_state_machine.dart';
import '../active_delivery/driver_active_delivery_timeline_card.dart';
import '../customer_contact/data/driver_customer_chat_repository.dart';
import '../customer_contact/data/driver_customer_contact_repository.dart';
import '../customer_contact/driver_customer_contact_card.dart';
import '../delivery_verification/data/driver_delivery_pin_repository.dart';
import '../delivery_verification/data/driver_delivery_qr_repository.dart';
import '../delivery_verification/domain/driver_delivery_pin_models.dart';
import '../delivery_verification/domain/driver_delivery_qr_models.dart';
import '../delivery_verification/driver_delivery_pin_screen.dart';
import '../delivery_verification/driver_delivery_qr_screen.dart';
import '../delivery_verification/driver_delivery_verification_card.dart';
import '../delivery_completion/data/driver_delivery_completion_repository.dart';
import '../delivery_completion/domain/driver_delivery_completion_models.dart';
import '../delivery_completion/driver_complete_delivery_card.dart';
import '../delivery_exceptions/data/driver_delivery_exception_repository.dart';
import '../delivery_exceptions/domain/driver_delivery_exception_models.dart';
import '../delivery_exceptions/driver_delivery_exception_card.dart';
import '../destination/data/driver_delivery_destination_repository.dart';
import '../destination/domain/driver_delivery_destination_models.dart';
import '../home/domain/driver_home_models.dart';
import '../support/data/driver_support_chat_repository.dart';
import '../support/driver_support_chat_screen.dart';
import 'data/driver_navigation_launcher.dart';
import 'data/driver_navigation_preference_store.dart';
import 'domain/driver_navigation_models.dart';
import 'driver_navigation_card.dart';

class DriverDeliveryNavigationScreen extends StatefulWidget {
  final DriverActiveDeliverySummary delivery;
  final AppConfig config;
  final DriverDeliveryDestinationRepository? destinationRepository;
  final DriverCustomerContactRepository? contactRepository;
  final DriverCustomerChatRepository? chatRepository;
  final DriverDeliveryPinRepository? pinRepository;
  final DriverDeliveryQrRepository? qrRepository;
  final DriverDeliveryCompletionRepository? completionRepository;
  final DriverDeliveryExceptionRepository? exceptionRepository;
  final DriverSupportChatRepository? supportRepository;
  final DriverDeliveryTimeline? timeline;
  final ValueChanged<DriverDeliveryState>? onStateChanged;
  final ValueChanged<DriverDeliveryExceptionReceipt>? onDeliveryException;
  final ValueChanged<DriverDeliveryCompletionReceipt>? onDeliveryCompleted;
  final DriverNavigationLauncher? launcher;
  final DriverNavigationPreferenceStore? preferenceStore;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverDeliveryNavigationScreen({
    super.key,
    required this.delivery,
    this.config = const AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    ),
    this.destinationRepository,
    this.contactRepository,
    this.chatRepository,
    this.pinRepository,
    this.qrRepository,
    this.completionRepository,
    this.exceptionRepository,
    this.supportRepository,
    this.timeline,
    this.onStateChanged,
    this.onDeliveryException,
    this.onDeliveryCompleted,
    this.launcher,
    this.preferenceStore,
    this.criticalActionGate,
  });

  @override
  State<DriverDeliveryNavigationScreen> createState() =>
      _DriverDeliveryNavigationScreenState();
}

class _DriverDeliveryNavigationScreenState
    extends State<DriverDeliveryNavigationScreen> {
  late final DriverDeliveryDestinationRepository _destinationRepository =
      widget.destinationRepository ??
          DriverDeliveryDestinationRepositoryFactory.create(widget.config);

  late final DriverDeliveryPinRepository _pinRepository =
      widget.pinRepository ??
          DriverDeliveryPinRepositoryFactory.create(widget.config);

  late final DriverDeliveryQrRepository _qrRepository = widget.qrRepository ??
      DriverDeliveryQrRepositoryFactory.create(widget.config);

  late final DriverDeliveryCompletionRepository _completionRepository =
      widget.completionRepository ??
          DriverDeliveryCompletionRepositoryFactory.create(widget.config);

  late final DriverDeliveryExceptionRepository _exceptionRepository =
      widget.exceptionRepository ??
          DriverDeliveryExceptionRepositoryFactory.create(widget.config);

  DriverDeliveryPinReceipt? _deliveryVerification;
  DriverDeliveryCompletionReceipt? _completionReceipt;
  DriverDeliveryExceptionReceipt? _exceptionReceipt;
  DriverDeliveryDestination? _destination;
  String? _destinationError;
  bool _loadingDestination = true;
  late DriverDeliveryTimeline _timeline;

  @override
  void initState() {
    super.initState();
    _timeline = widget.timeline ??
        DriverDeliveryStateMachine.seed(
          orderNumber: widget.delivery.orderNumber,
          currentState: widget.delivery.resolvedState,
        );
    _loadDestination();
    _loadExistingException();
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

  void _openSupport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverSupportChatScreen(
          config: widget.config,
          delivery: widget.delivery,
          repository: widget.supportRepository,
        ),
      ),
    );
  }

  Future<void> _loadExistingException() async {
    final receipt = await _exceptionRepository.loadActiveException(
      orderNumber: widget.delivery.orderNumber,
    );
    if (!mounted || receipt == null) return;
    setState(() => _exceptionReceipt = receipt);
    final target =
        receipt.reason == DriverDeliveryExceptionReason.returnToBranch
            ? DriverDeliveryState.returnedToBranch
            : DriverDeliveryState.failedDelivery;
    _advanceTimeline(
      target,
      source: 'delivery_exception_restore',
      note: receipt.reason.label,
    );
  }

  Future<void> _loadDestination() async {
    if (mounted) {
      setState(() {
        _loadingDestination = true;
        _destinationError = null;
      });
    }

    final result = await _destinationRepository.load(
      orderNumber: widget.delivery.orderNumber,
    );
    if (!mounted) return;

    setState(() {
      _loadingDestination = false;
      _destination = result.destination;
      _destinationError = result.errorMessage;
    });
  }

  bool _ensureCriticalActionAvailable(DriverCriticalAction action) {
    if (driverCriticalActionAllowed(widget.criticalActionGate)) return true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(action.offlineMessage),
      ),
    );
    return false;
  }

  Future<void> _openDeliveryPinVerification() async {
    if (!_ensureCriticalActionAvailable(
      DriverCriticalAction.customerVerification,
    )) {
      return;
    }
    if (!_advanceTimeline(
      DriverDeliveryState.verificationPending,
      source: 'customer_verification',
      note: 'Driver began customer PIN verification.',
    )) {
      return;
    }

    final receipt = await Navigator.of(context).push<DriverDeliveryPinReceipt>(
      MaterialPageRoute<DriverDeliveryPinReceipt>(
        builder: (_) => DriverDeliveryPinScreen(
          config: widget.config,
          delivery: widget.delivery,
          repository: _pinRepository,
          criticalActionGate: widget.criticalActionGate,
        ),
      ),
    );

    if (!mounted || receipt == null) return;
    setState(() => _deliveryVerification = receipt);
  }

  Future<void> _openDeliveryQrVerification() async {
    if (!_ensureCriticalActionAvailable(
      DriverCriticalAction.customerVerification,
    )) {
      return;
    }
    if (!_advanceTimeline(
      DriverDeliveryState.verificationPending,
      source: 'customer_verification',
      note: 'Driver began customer QR verification.',
    )) {
      return;
    }

    final outcome =
        await Navigator.of(context).push<DriverDeliveryQrScreenOutcome>(
      MaterialPageRoute<DriverDeliveryQrScreenOutcome>(
        builder: (_) => DriverDeliveryQrScreen(
          config: widget.config,
          delivery: widget.delivery,
          repository: _qrRepository,
          criticalActionGate: widget.criticalActionGate,
        ),
      ),
    );

    if (!mounted || outcome == null) return;
    if (outcome.receipt != null) {
      setState(() => _deliveryVerification = outcome.receipt);
      return;
    }
    if (outcome.usePinFallback) {
      await _openDeliveryPinVerification();
    }
  }

  void _handleDeliveryCompleted(DriverDeliveryCompletionReceipt receipt) {
    if (!mounted) return;
    if (!_advanceTimeline(
      DriverDeliveryState.delivered,
      source: 'delivery_completion',
      note: 'Verified customer handoff completed.',
    )) {
      return;
    }
    setState(() => _completionReceipt = receipt);
    widget.onDeliveryCompleted?.call(receipt);
  }

  void _handleDeliveryException(DriverDeliveryExceptionReceipt receipt) {
    if (!mounted) return;
    final target =
        receipt.reason == DriverDeliveryExceptionReason.returnToBranch
            ? DriverDeliveryState.returnedToBranch
            : DriverDeliveryState.failedDelivery;
    if (!_advanceTimeline(
      target,
      source: 'delivery_exception',
      note: receipt.reason.label,
    )) {
      return;
    }
    setState(() => _exceptionReceipt = receipt);
    widget.onDeliveryException?.call(receipt);
  }

  DriverNavigationTarget get _navigationTarget {
    final destination = _destination;
    if (destination != null) {
      return DriverNavigationTarget(
        label: destination.addressLabel,
        address: destination.streetAddress,
        latitude: destination.latitude,
        longitude: destination.longitude,
      );
    }

    return DriverNavigationTarget(
      label: widget.delivery.destinationArea,
      address: widget.delivery.destinationArea,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _completionReceipt == null
              ? 'Delivery Destination'
              : 'Delivery Complete',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
              children: [
                _DeliveryNavigationHeader(
                  delivery: widget.delivery,
                  state: _timeline.currentState,
                  completion: _completionReceipt,
                ),
                const SizedBox(height: 14),
                if (_loadingDestination)
                  const _DestinationLoadingCard()
                else if (_destination != null) ...[
                  if (_destinationRepository.source ==
                      DriverDeliveryDestinationDataSource.demo) ...[
                    const _DemoDestinationNotice(),
                    const SizedBox(height: 14),
                  ],
                  _DestinationDetailsCard(destination: _destination!),
                  const SizedBox(height: 14),
                  _DestinationMapPreview(destination: _destination!),
                ] else
                  _DestinationUnavailableCard(
                    message: _destinationError ??
                        'Delivery destination is unavailable.',
                    area: widget.delivery.destinationArea,
                    onRetry: _loadDestination,
                  ),
                const SizedBox(height: 14),
                DriverActiveDeliveryTimelineCard(timeline: _timeline),
                const SizedBox(height: 14),
                DriverNavigationCard(
                  target: _navigationTarget,
                  launcher: widget.launcher,
                  preferenceStore: widget.preferenceStore,
                ),
                const SizedBox(height: 14),
                DriverCustomerContactCard(
                  config: widget.config,
                  delivery: widget.delivery,
                  contactRepository: widget.contactRepository,
                  chatRepository: widget.chatRepository,
                ),
                const SizedBox(height: 14),
                _GetinSupportCard(onPressed: _openSupport),
                const SizedBox(height: 14),
                if (_timeline.currentState.isProblemState)
                  _DeliveryStateLockedNotice(state: _timeline.currentState)
                else
                  DriverDeliveryVerificationCard(
                    receipt: _deliveryVerification,
                    onVerifyPin: _openDeliveryPinVerification,
                    onVerifyQr: _openDeliveryQrVerification,
                  ),
                const SizedBox(height: 14),
                DriverDeliveryExceptionCard(
                  delivery: widget.delivery,
                  config: widget.config,
                  repository: _exceptionRepository,
                  receipt: _exceptionReceipt,
                  deliveryCompleted: _completionReceipt != null,
                  onReported: _handleDeliveryException,
                ),
                const SizedBox(height: 14),
                if (_exceptionReceipt == null)
                  DriverCompleteDeliveryCard(
                    delivery: widget.delivery,
                    verification: _deliveryVerification,
                    repository: _completionRepository,
                    stateAllowsCompletion: _timeline.currentState ==
                        DriverDeliveryState.verificationPending,
                    onCompleted: _handleDeliveryCompleted,
                    criticalActionGate: widget.criticalActionGate,
                  )
                else
                  const _ExceptionBlocksCompletionNotice(),
                const SizedBox(height: 14),
                const _PrivacyNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GetinSupportCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _GetinSupportCard({required this.onPressed});

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.greenDark.withOpacity(.07),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Getin Support',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Order-aware help from Getin operations.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onPressed,
            child: const Text('SUPPORT'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryStateLockedNotice extends StatelessWidget {
  final DriverDeliveryState state;

  const _DeliveryStateLockedNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withOpacity(.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${state.label} locks normal delivery progression. Verification and completion cannot continue until Getin operations resolves the order.',
              style: const TextStyle(
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
}

class _DeliveryNavigationHeader extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;
  final DriverDeliveryState state;
  final DriverDeliveryCompletionReceipt? completion;

  const _DeliveryNavigationHeader({
    required this.delivery,
    required this.state,
    required this.completion,
  });

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
                  delivery.orderNumber,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: completion == null
                    ? state.label.toUpperCase()
                    : completion!.isDemo
                        ? 'DELIVERED • DEMO'
                        : 'DELIVERED',
                tone: state.isProblemState
                    ? StatusTone.warning
                    : StatusTone.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Delivery area',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            delivery.destinationArea,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoDestinationNotice extends StatelessWidget {
  const _DemoDestinationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBD8A3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.warning, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Development demo destination. These address details and coordinates are sample data only and were not received from Laravel.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 11,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationLoadingCard extends StatelessWidget {
  const _DestinationLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading delivery destination…',
              style: TextStyle(
                color: AppColors.greenDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationUnavailableCard extends StatelessWidget {
  final String message;
  final String area;
  final VoidCallback onRetry;

  const _DestinationUnavailableCard({
    required this.message,
    required this.area,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.location_off_outlined, color: AppColors.danger),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Exact destination unavailable',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only the already-known area ($area) remains available for navigation until the exact destination is supplied.',
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Destination'),
          ),
        ],
      ),
    );
  }
}

class _DestinationDetailsCard extends StatelessWidget {
  final DriverDeliveryDestination destination;

  const _DestinationDetailsCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.beige.withOpacity(.42),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery destination',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      destination.addressLabel,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DestinationRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: destination.streetAddress,
          ),
          _DestinationRow(
            icon: Icons.map_outlined,
            label: 'Area',
            value: destination.area,
          ),
          const Divider(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [
                    _DestinationField(
                      label: 'Building',
                      value: destination.building,
                    ),
                    const SizedBox(height: 10),
                    _DestinationField(
                      label: 'Floor',
                      value: destination.floor,
                    ),
                    const SizedBox(height: 10),
                    _DestinationField(
                      label: 'Apartment',
                      value: destination.apartment,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _DestinationField(
                      label: 'Building',
                      value: destination.building,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DestinationField(
                      label: 'Floor',
                      value: destination.floor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DestinationField(
                      label: 'Apartment',
                      value: destination.apartment,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Delivery instructions',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ...destination.deliveryInstructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      instruction,
                      style: const TextStyle(
                        color: AppColors.greenDark,
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

class _DestinationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DestinationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 12.5,
                    height: 1.35,
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

class _DestinationField extends StatelessWidget {
  final String label;
  final String value;

  const _DestinationField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
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
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

class _DestinationMapPreview extends StatelessWidget {
  final DriverDeliveryDestination destination;

  const _DestinationMapPreview({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECE5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _MapGridPainter()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greenDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.beige, width: 3),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        color: Color(0x1A000000),
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Exact delivery pin',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.greenDark.withOpacity(.9),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '${destination.latitude.toStringAsFixed(5)}, ${destination.longitude.toStringAsFixed(5)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final smallRoadPaint = Paint()
      ..color = const Color(0xFFD4DBD2)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-20, size.height * .72),
      Offset(size.width + 30, size.height * .24),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * .18, -20),
      Offset(size.width * .62, size.height + 20),
      roadPaint,
    );
    canvas.drawLine(
      Offset(-10, size.height * .26),
      Offset(size.width + 10, size.height * .72),
      smallRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * .78, -10),
      Offset(size.width * .35, size.height + 10),
      smallRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExceptionBlocksCompletionNotice extends StatelessWidget {
  const _ExceptionBlocksCompletionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBD8A3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, color: AppColors.warning, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete Delivery is locked because a delivery exception has been reported. Keep the order active until Getin operations resolves the issue.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.green, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Exact destination details are shown only for the active accepted delivery. Customer profile, payment and unrelated account information remain hidden.',
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
