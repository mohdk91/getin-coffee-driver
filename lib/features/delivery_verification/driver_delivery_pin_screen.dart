import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_delivery_pin_repository.dart';
import 'domain/driver_delivery_pin_models.dart';
import 'driver_verification_issue_card.dart';

class DriverDeliveryPinScreen extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary delivery;
  final DriverDeliveryPinRepository? repository;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverDeliveryPinScreen({
    super.key,
    required this.config,
    required this.delivery,
    this.repository,
    this.criticalActionGate,
  });

  @override
  State<DriverDeliveryPinScreen> createState() =>
      _DriverDeliveryPinScreenState();
}

class _DriverDeliveryPinScreenState extends State<DriverDeliveryPinScreen> {
  late final DriverDeliveryPinRepository _repository = widget.repository ??
      DriverDeliveryPinRepositoryFactory.create(widget.config);
  final TextEditingController _controller = TextEditingController();

  DriverDeliveryPinChallenge? _challenge;
  DriverDeliveryPinReceipt? _receipt;
  String? _loadError;
  String? _verificationError;
  DriverDeliveryPinFailureReason? _failureReason;
  bool _customerNeedsHelp = false;
  bool _loading = true;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadChallenge() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        _verificationError = null;
        _failureReason = null;
        _customerNeedsHelp = false;
      });
    }

    final result = await _repository.loadChallenge(
      apiOrderId: widget.delivery.apiOrderId,
      orderNumber: widget.delivery.orderNumber,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _challenge = result.challenge;
      _loadError = result.errorMessage;
    });
  }

  Future<void> _verify() async {
    final challenge = _challenge;
    if (challenge == null || _verifying || _receipt != null) return;
    if (!driverCriticalActionAllowed(widget.criticalActionGate)) {
      setState(() {
        _verificationError =
            DriverCriticalAction.customerVerification.offlineMessage;
        _failureReason = DriverDeliveryPinFailureReason.unavailable;
      });
      return;
    }

    final code = _controller.text.trim();
    final validShape = RegExp(r'^\d{4,6}$').hasMatch(code) &&
        code.length == challenge.codeLength;
    if (!validShape) {
      setState(() {
        _verificationError =
            'Enter the complete ${challenge.codeLength}-digit delivery code.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _verificationError = null;
      _failureReason = null;
    });

    final result = await _repository.verifyPin(
      apiOrderId: widget.delivery.apiOrderId,
      challenge: challenge,
      orderNumber: widget.delivery.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      code: code,
    );
    if (!mounted) return;

    setState(() {
      _verifying = false;
      _receipt = result.receipt;
      _verificationError = result.isSuccess ? null : result.message;
      _failureReason = result.failureReason;
    });
  }

  void _returnToDelivery() {
    Navigator.of(context).pop(_receipt);
  }

  void _showCustomerHelp() {
    setState(() => _customerNeedsHelp = true);
  }

  void _hideCustomerHelp() {
    setState(() => _customerNeedsHelp = false);
  }

  bool get _verificationLocked {
    switch (_failureReason) {
      case DriverDeliveryPinFailureReason.expired:
      case DriverDeliveryPinFailureReason.wrongOrder:
      case DriverDeliveryPinFailureReason.wrongCustomer:
      case DriverDeliveryPinFailureReason.wrongDriver:
      case DriverDeliveryPinFailureReason.alreadyUsed:
      case DriverDeliveryPinFailureReason.tooManyAttempts:
      case DriverDeliveryPinFailureReason.unavailable:
        return true;
      case DriverDeliveryPinFailureReason.invalidCode:
      case null:
        return false;
    }
  }

  String _issueTitle(DriverDeliveryPinFailureReason reason) {
    switch (reason) {
      case DriverDeliveryPinFailureReason.invalidCode:
        return 'Invalid code';
      case DriverDeliveryPinFailureReason.expired:
        return 'Code expired';
      case DriverDeliveryPinFailureReason.wrongOrder:
        return 'Wrong order';
      case DriverDeliveryPinFailureReason.wrongCustomer:
        return 'Customer mismatch';
      case DriverDeliveryPinFailureReason.wrongDriver:
        return 'Driver mismatch';
      case DriverDeliveryPinFailureReason.alreadyUsed:
        return 'Code already used';
      case DriverDeliveryPinFailureReason.tooManyAttempts:
        return 'Too many attempts';
      case DriverDeliveryPinFailureReason.unavailable:
        return 'Verification unavailable';
    }
  }

  String _issueActionLabel(DriverDeliveryPinFailureReason reason) {
    return reason == DriverDeliveryPinFailureReason.invalidCode
        ? 'Try Code Again'
        : 'Reload Verification';
  }

  void _retryIssue() {
    final reason = _failureReason;
    if (reason == DriverDeliveryPinFailureReason.invalidCode) {
      setState(() {
        _failureReason = null;
        _verificationError = null;
      });
      _controller.clear();
      return;
    }
    _controller.clear();
    _loadChallenge();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Delivery Verification')),
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
                _Header(
                  delivery: widget.delivery,
                  verified: _receipt != null,
                ),
                const SizedBox(height: 14),
                if (_repository.source == DriverDeliveryPinDataSource.demo) ...[
                  const _DemoNotice(),
                  const SizedBox(height: 14),
                ],
                if (_loading)
                  const _LoadingCard()
                else if (_challenge == null)
                  _UnavailableCard(
                    message: _loadError ??
                        'Delivery verification is currently unavailable.',
                    onRetry: _loadChallenge,
                  )
                else if (_receipt != null)
                  _VerifiedCard(receipt: _receipt!)
                else ...[
                  _PinEntryCard(
                    challenge: _challenge!,
                    controller: _controller,
                    errorMessage:
                        _failureReason == null ? _verificationError : null,
                    verifying: _verifying,
                    locked: _verificationLocked,
                    onVerify: _verify,
                  ),
                  if (_failureReason != null) ...[
                    const SizedBox(height: 12),
                    DriverVerificationIssueCard(
                      title: _issueTitle(_failureReason!),
                      message: _verificationError ??
                          'Verification failed. No delivery state changed.',
                      actionLabel: _issueActionLabel(_failureReason!),
                      actionIcon: _failureReason ==
                              DriverDeliveryPinFailureReason.invalidCode
                          ? Icons.replay_rounded
                          : Icons.refresh_rounded,
                      onAction: _retryIssue,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CustomerCodeHelpCard(
                    expanded: _customerNeedsHelp,
                    onShow: _showCustomerHelp,
                    onHide: _hideCustomerHelp,
                  ),
                ],
                const SizedBox(height: 14),
                _CompletionSafetyCard(verified: _receipt != null),
                if (_receipt != null) ...[
                  const SizedBox(height: 14),
                  GetinActionButton(
                    label: 'Back to Delivery',
                    icon: Icons.arrow_back_rounded,
                    onPressed: _returnToDelivery,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;
  final bool verified;

  const _Header({
    required this.delivery,
    required this.verified,
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
                label: verified ? 'PIN VERIFIED' : 'PIN REQUIRED',
                tone: verified ? StatusTone.success : StatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Ask customer for their delivery code',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'The one-time code confirms the handoff belongs to this order, customer, and assigned driver.',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

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
              'Development demo only. Use PIN 4821. Verification is local and does not update Laravel or the Customer App.',
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

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
              'Preparing delivery verification…',
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

class _UnavailableCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _UnavailableCard({required this.message, required this.onRetry});

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
              Icon(Icons.lock_clock_outlined, color: AppColors.danger),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Verification unavailable',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GetinActionButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            secondary: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _PinEntryCard extends StatelessWidget {
  final DriverDeliveryPinChallenge challenge;
  final TextEditingController controller;
  final String? errorMessage;
  final bool verifying;
  final bool locked;
  final VoidCallback onVerify;

  const _PinEntryCard({
    required this.challenge,
    required this.controller,
    required this.errorMessage,
    required this.verifying,
    required this.locked,
    required this.onVerify,
  });

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
          const Text(
            'Delivery Code',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the ${challenge.codeLength}-digit one-time code shown to the customer.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled: !verifying && !locked,
            autofocus: false,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            onSubmitted: (_) {
              if (!verifying && !locked) onVerify();
            },
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 26,
              letterSpacing: 11,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              hintText:
                  List<String>.filled(challenge.codeLength, '•').join(' '),
              counterText: '',
              errorText: errorMessage,
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 14),
          GetinActionButton(
            label: verifying ? 'Verifying…' : 'Verify Delivery',
            icon: verifying ? null : Icons.verified_user_outlined,
            onPressed: verifying || locked ? null : onVerify,
          ),
        ],
      ),
    );
  }
}

class _VerifiedCard extends StatelessWidget {
  final DriverDeliveryPinReceipt receipt;

  const _VerifiedCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8D8C9)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Delivery Verified',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            receipt.isDemo
                ? 'PIN verified locally for this demo order. Laravel has not acknowledged the handoff.'
                : 'PIN verification was acknowledged for this order.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionSafetyCard extends StatelessWidget {
  final bool verified;

  const _CompletionSafetyCard({required this.verified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            verified ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            color: verified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              verified
                  ? 'PIN verification is complete. The order is not marked Delivered here; Complete Delivery remains a separate server-confirmed action.'
                  : 'Complete Delivery stays locked until customer verification succeeds. Saving a code locally must never bypass this requirement.',
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCodeHelpCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onShow;
  final VoidCallback onHide;

  const _CustomerCodeHelpCard({
    required this.expanded,
    required this.onShow,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return GetinActionButton(
        label: "Customer can't find the code",
        icon: Icons.help_outline_rounded,
        secondary: true,
        onPressed: onShow,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.info),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  "Customer can't find the code",
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Ask the customer to open the current order tracking screen and check the Delivery Code. If the code is unavailable, go back and use Scan Customer QR. Contact Getin Support if neither method is available.',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Verification is still required. Never complete the delivery without a valid PIN or customer QR.',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GetinActionButton(
            label: 'Hide Help',
            icon: Icons.close_rounded,
            secondary: true,
            onPressed: onHide,
          ),
        ],
      ),
    );
  }
}
