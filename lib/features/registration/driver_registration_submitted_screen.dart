import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'domain/driver_registration_models.dart';

class DriverRegistrationSubmittedScreen extends StatelessWidget {
  final DriverRegistrationReceipt receipt;
  final DriverRegistrationSource source;

  const DriverRegistrationSubmittedScreen({
    super.key,
    required this.receipt,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final demo = source == DriverRegistrationSource.demo;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 42,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    demo ? 'Demo application created' : 'Application submitted',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    demo
                        ? 'This is a local development receipt only. Nothing was uploaded to Getin or Laravel.'
                        : 'Your application has been sent for review.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _ReceiptRow(
                            label: 'Application ID',
                            value: receipt.applicationId),
                        const Divider(height: 24),
                        _ReceiptRow(
                            label: 'Status', value: receipt.statusLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'New applications start in Pending review. Only drivers whose verification status becomes Approved may enter delivery operations and receive jobs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.greenDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
