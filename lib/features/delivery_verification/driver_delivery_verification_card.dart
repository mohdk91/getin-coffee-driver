import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import 'domain/driver_delivery_pin_models.dart';

class DriverDeliveryVerificationCard extends StatelessWidget {
  final DriverDeliveryPinReceipt? receipt;
  final VoidCallback onVerifyPin;
  final VoidCallback onVerifyQr;
  final bool enabled;
  final String? lockedMessage;

  const DriverDeliveryVerificationCard({
    super.key,
    required this.receipt,
    required this.onVerifyPin,
    required this.onVerifyQr,
    this.enabled = true,
    this.lockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final verified = receipt != null;
    final viaQr = receipt?.verificationType == 'qr';

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
          Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : Icons.verified_user_outlined,
                color: verified ? AppColors.success : AppColors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verified ? 'Delivery Verified' : 'Customer verification',
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            verified
                ? 'Customer handoff verified by ${viaQr ? 'QR' : 'PIN'}. Delivery completion is still a separate server-confirmed step.'
                : enabled
                    ? 'Verify the handoff with the customer PIN or scan the customer QR. Both methods represent the same secure delivery verification.'
                    : lockedMessage ??
                        'Confirm arrival at the customer before starting delivery verification.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (verified)
            GetinActionButton(
              label: viaQr ? 'QR Verified' : 'PIN Verified',
              icon: Icons.check_circle_outline,
              secondary: true,
              onPressed: null,
            )
          else ...[
            GetinActionButton(
              label: 'Enter Delivery Code',
              icon: Icons.pin_rounded,
              onPressed: enabled ? onVerifyPin : null,
            ),
            const SizedBox(height: 10),
            GetinActionButton(
              label: 'Scan Customer QR',
              icon: Icons.qr_code_scanner_rounded,
              secondary: true,
              onPressed: enabled ? onVerifyQr : null,
            ),
          ],
        ],
      ),
    );
  }
}
