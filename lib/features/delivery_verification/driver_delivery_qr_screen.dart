import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_delivery_qr_repository.dart';
import 'domain/driver_delivery_qr_models.dart';
import 'driver_verification_issue_card.dart';

class DriverDeliveryQrScreen extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary delivery;
  final DriverDeliveryQrRepository? repository;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverDeliveryQrScreen({
    super.key,
    required this.config,
    required this.delivery,
    this.repository,
    this.criticalActionGate,
  });

  @override
  State<DriverDeliveryQrScreen> createState() => _DriverDeliveryQrScreenState();
}

class _DriverDeliveryQrScreenState extends State<DriverDeliveryQrScreen> {
  late final DriverDeliveryQrRepository _repository = widget.repository ??
      DriverDeliveryQrRepositoryFactory.create(widget.config);

  DriverDeliveryQrChallenge? _challenge;
  String? _loadError;
  String? _verificationError;
  DriverDeliveryQrFailureReason? _failureReason;
  bool _loading = true;
  bool _verifying = false;
  DriverDeliveryQrScreenOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        _verificationError = null;
        _failureReason = null;
      });
    }

    final result = await _repository.loadChallenge(
      orderNumber: widget.delivery.orderNumber,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _challenge = result.challenge;
      _loadError = result.errorMessage;
    });
  }

  Future<void> _scanDemoQr() async {
    final challenge = _challenge;
    if (challenge == null || _verifying || _outcome?.receipt != null) return;
    if (!driverCriticalActionAllowed(widget.criticalActionGate)) {
      setState(() {
        _verificationError =
            DriverCriticalAction.customerVerification.offlineMessage;
        _failureReason = DriverDeliveryQrFailureReason.unavailable;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _verificationError = null;
      _failureReason = null;
    });

    final result = await _repository.verifyQr(
      challenge: challenge,
      orderNumber: widget.delivery.orderNumber,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      qrPayload: DemoDriverDeliveryQrRepository.demoPayload,
    );
    if (!mounted) return;

    setState(() {
      _verifying = false;
      _verificationError = result.isSuccess ? null : result.message;
      _failureReason = result.failureReason;
      if (result.receipt != null) {
        _outcome = DriverDeliveryQrScreenOutcome.verified(result.receipt!);
      }
    });
  }

  void _usePinFallback() {
    Navigator.of(context).pop(const DriverDeliveryQrScreenOutcome.usePin());
  }

  void _simulateCameraUnavailable() {
    setState(() {
      _failureReason = DriverDeliveryQrFailureReason.cameraUnavailable;
      _verificationError =
          'Camera is unavailable. Delivery remains unverified. Retry the camera or use the delivery PIN instead.';
    });
  }

  void _retryQrIssue() {
    final reason = _failureReason;
    if (reason == DriverDeliveryQrFailureReason.invalidQr ||
        reason == DriverDeliveryQrFailureReason.cameraUnavailable) {
      setState(() {
        _failureReason = null;
        _verificationError = null;
      });
      return;
    }
    _loadChallenge();
  }

  String _issueTitle(DriverDeliveryQrFailureReason reason) {
    switch (reason) {
      case DriverDeliveryQrFailureReason.invalidQr:
        return 'Invalid QR';
      case DriverDeliveryQrFailureReason.expired:
        return 'QR expired';
      case DriverDeliveryQrFailureReason.wrongOrder:
        return 'Wrong order';
      case DriverDeliveryQrFailureReason.wrongCustomer:
        return 'Customer mismatch';
      case DriverDeliveryQrFailureReason.wrongDriver:
        return 'Driver mismatch';
      case DriverDeliveryQrFailureReason.alreadyUsed:
        return 'QR already used';
      case DriverDeliveryQrFailureReason.tooManyAttempts:
        return 'Too many attempts';
      case DriverDeliveryQrFailureReason.cameraUnavailable:
        return 'Camera unavailable';
      case DriverDeliveryQrFailureReason.unavailable:
        return 'Verification unavailable';
    }
  }

  String _issueActionLabel(DriverDeliveryQrFailureReason reason) {
    if (reason == DriverDeliveryQrFailureReason.cameraUnavailable) {
      return 'Retry Camera';
    }
    if (reason == DriverDeliveryQrFailureReason.invalidQr) {
      return 'Try QR Again';
    }
    return 'Reload QR Verification';
  }

  void _returnToDelivery() {
    final outcome = _outcome;
    if (outcome == null) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final verified = _outcome?.receipt != null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Scan Customer QR')),
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
                _QrHeader(delivery: widget.delivery),
                const SizedBox(height: 14),
                if (_repository.source == DriverDeliveryQrDataSource.demo) ...[
                  const _DemoQrNotice(),
                  const SizedBox(height: 14),
                ],
                if (_loading)
                  const _QrLoadingCard()
                else if (_challenge == null)
                  _QrUnavailableCard(
                    message: _loadError ??
                        'Customer QR verification is currently unavailable.',
                    onRetry: _loadChallenge,
                  )
                else if (verified)
                  _QrVerifiedCard(isDemo: _outcome!.receipt!.isDemo)
                else if (_failureReason != null)
                  DriverVerificationIssueCard(
                    title: _issueTitle(_failureReason!),
                    message: _verificationError ??
                        'QR verification failed. No delivery state changed.',
                    icon: _failureReason ==
                            DriverDeliveryQrFailureReason.cameraUnavailable
                        ? Icons.no_photography_outlined
                        : Icons.error_outline_rounded,
                    actionLabel: _issueActionLabel(_failureReason!),
                    actionIcon: Icons.refresh_rounded,
                    onAction: _retryQrIssue,
                    secondaryActionLabel: 'Enter Code Instead',
                    secondaryActionIcon: Icons.pin_rounded,
                    onSecondaryAction: _usePinFallback,
                  )
                else
                  _QrScannerCard(
                    verifying: _verifying,
                    isDemo:
                        _repository.source == DriverDeliveryQrDataSource.demo,
                    onScan: _scanDemoQr,
                    onCameraUnavailable: _simulateCameraUnavailable,
                  ),
                const SizedBox(height: 14),
                _QrSafetyCard(verified: verified),
                const SizedBox(height: 14),
                if (verified)
                  GetinActionButton(
                    label: 'Back to Delivery',
                    icon: Icons.arrow_back_rounded,
                    onPressed: _returnToDelivery,
                  )
                else
                  GetinActionButton(
                    label: 'Enter Code Instead',
                    icon: Icons.pin_rounded,
                    secondary: true,
                    onPressed: _usePinFallback,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrHeader extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;

  const _QrHeader({required this.delivery});

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
              const StatusPill(
                label: 'QR VERIFICATION',
                tone: StatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Scan the customer delivery QR',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'The QR and delivery PIN represent the same secure handoff verification. Use the PIN if scanning is unavailable.',
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

class _DemoQrNotice extends StatelessWidget {
  const _DemoQrNotice();

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
              'Development demo only. Camera scanning is not claimed as live yet. Tap Simulate Customer QR Scan to exercise the same verification result locally.',
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

class _QrLoadingCard extends StatelessWidget {
  const _QrLoadingCard();

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
              'Preparing customer QR verification…',
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

class _QrUnavailableCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QrUnavailableCard({required this.message, required this.onRetry});

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
          const Text(
            'QR verification unavailable',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
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

class _QrScannerCard extends StatelessWidget {
  final bool verifying;
  final bool isDemo;
  final VoidCallback onScan;
  final VoidCallback onCameraUnavailable;

  const _QrScannerCard({
    required this.verifying,
    required this.isDemo,
    required this.onScan,
    required this.onCameraUnavailable,
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
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.greenDark,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 158,
                  height: 158,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.beige, width: 3),
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 82,
                ),
                Positioned(
                  bottom: 16,
                  child: Text(
                    isDemo ? 'DEMO SCANNER' : 'CUSTOMER QR',
                    style: const TextStyle(
                      color: AppColors.beige,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GetinActionButton(
            label: verifying
                ? 'Verifying QR…'
                : isDemo
                    ? 'Simulate Customer QR Scan'
                    : 'Scan Customer QR',
            icon: verifying ? null : Icons.qr_code_scanner_rounded,
            onPressed: verifying || !isDemo ? null : onScan,
          ),
          if (isDemo) ...[
            const SizedBox(height: 9),
            GetinActionButton(
              label: 'Simulate Camera Unavailable',
              icon: Icons.no_photography_outlined,
              secondary: true,
              onPressed: verifying ? null : onCameraUnavailable,
            ),
          ],
        ],
      ),
    );
  }
}

class _QrVerifiedCard extends StatelessWidget {
  final bool isDemo;

  const _QrVerifiedCard({required this.isDemo});

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
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isDemo
                ? 'Customer QR verified locally for this demo order. Laravel has not acknowledged the handoff.'
                : 'Customer QR verification was acknowledged for this order.',
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

class _QrSafetyCard extends StatelessWidget {
  final bool verified;

  const _QrSafetyCard({required this.verified});

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
                  ? 'QR verification is complete. The order is not marked Delivered here; Complete Delivery remains a separate server-confirmed action for Driver Task #22.'
                  : 'Complete Delivery stays locked until customer PIN or QR verification succeeds. QR and PIN are alternative verification methods for the same handoff.',
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
