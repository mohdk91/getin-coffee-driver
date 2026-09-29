import 'package:flutter/material.dart';

import '../../core/offline/driver_offline_safety.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../delivery_verification/domain/driver_delivery_pin_models.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_delivery_completion_repository.dart';
import 'domain/driver_delivery_completion_models.dart';

class DriverCompleteDeliveryCard extends StatefulWidget {
  final DriverActiveDeliverySummary delivery;
  final DriverDeliveryPinReceipt? verification;
  final DriverDeliveryCompletionRepository repository;
  final bool stateAllowsCompletion;
  final ValueChanged<DriverDeliveryCompletionReceipt>? onCompleted;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverCompleteDeliveryCard({
    super.key,
    required this.delivery,
    required this.verification,
    required this.repository,
    this.stateAllowsCompletion = true,
    this.onCompleted,
    this.criticalActionGate,
  });

  @override
  State<DriverCompleteDeliveryCard> createState() =>
      _DriverCompleteDeliveryCardState();
}

class _DriverCompleteDeliveryCardState
    extends State<DriverCompleteDeliveryCard> {
  bool _submitting = false;
  String? _errorMessage;
  DriverDeliveryCompletionReceipt? _receipt;

  Future<void> _complete() async {
    final verification = widget.verification;
    if (!driverCriticalActionAllowed(widget.criticalActionGate)) {
      setState(() {
        _errorMessage = DriverCriticalAction.completeDelivery.offlineMessage;
      });
      return;
    }
    if (verification == null ||
        !widget.stateAllowsCompletion ||
        _submitting ||
        _receipt != null) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await widget.repository.completeDelivery(
      orderNumber: widget.delivery.orderNumber,
      verification: verification,
    );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      if (result.isSuccess) {
        _receipt = result.receipt;
      } else {
        _errorMessage = result.message;
      }
    });

    if (result.receipt != null) {
      widget.onCompleted?.call(result.receipt!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    if (receipt != null) {
      return _CompletedDeliveryReceipt(receipt: receipt);
    }

    final verified = widget.verification != null;
    final ready = verified && widget.stateAllowsCompletion;
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
                  color: (verified ? AppColors.success : AppColors.muted)
                      .withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  verified ? Icons.check_circle_rounded : Icons.lock_rounded,
                  color: verified ? AppColors.success : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Delivery',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ready
                          ? 'Customer handoff is verified. Confirm the final delivery state.'
                          : verified
                              ? 'Customer handoff is verified, but the delivery timeline is not in verification_pending.'
                              : 'Customer verification is required before this action unlocks.',
                      style: const TextStyle(
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
          if (verified) ...[
            const SizedBox(height: 14),
            StatusPill(
              label:
                  '${widget.verification!.verificationType.toUpperCase()} VERIFIED',
              tone: StatusTone.success,
              icon: Icons.verified_rounded,
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withOpacity(.20)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          GetinActionButton(
            label: _submitting ? 'Confirming with Getin…' : 'Complete Delivery',
            icon: Icons.task_alt_rounded,
            onPressed: ready && !_submitting ? _complete : null,
          ),
          const SizedBox(height: 10),
          const Text(
            'Critical action: the production app must wait for server acknowledgement before showing an order as Delivered.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedDeliveryReceipt extends StatelessWidget {
  final DriverDeliveryCompletionReceipt receipt;

  const _CompletedDeliveryReceipt({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt_rounded, color: AppColors.success, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery Completed',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatusPill(
            label: receipt.isDemo ? 'DELIVERED • DEMO' : 'DELIVERED',
            tone: StatusTone.success,
          ),
          const SizedBox(height: 14),
          _ReceiptRow(label: 'Order', value: receipt.orderNumber),
          _ReceiptRow(label: 'Driver', value: receipt.driverReference),
          _ReceiptRow(
            label: 'Verification',
            value: receipt.verificationType.toUpperCase(),
          ),
          _ReceiptRow(label: 'Order state', value: receipt.orderState),
          _ReceiptRow(
            label: 'GPS',
            value: receipt.latitude == null || receipt.longitude == null
                ? 'Not available'
                : '${receipt.latitude!.toStringAsFixed(5)}, ${receipt.longitude!.toStringAsFixed(5)}',
          ),
          _ReceiptRow(
            label: 'Server timestamp',
            value: receipt.serverTimestamp?.toIso8601String() ??
                'Not acknowledged by Laravel',
          ),
          if (receipt.isDemo) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEBD8A3)),
              ),
              child: const Text(
                'Development only: this is a local completion receipt. Laravel and the Customer App were not updated.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          GetinActionButton(
            label: 'Back to Driver Home',
            icon: Icons.home_rounded,
            secondary: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
