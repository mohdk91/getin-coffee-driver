import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/driver_registration_models.dart';

class DriverRegistrationProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const DriverRegistrationProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 5,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? AppColors.gold : AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class DriverRegistrationSectionCard extends StatelessWidget {
  final Widget child;

  const DriverRegistrationSectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D211C),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DriverRegistrationModeBanner extends StatelessWidget {
  final DriverRegistrationSource source;

  const DriverRegistrationModeBanner({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final demo = source == DriverRegistrationSource.demo;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: demo ? const Color(0xFFF0E8D4) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            demo ? Icons.science_outlined : Icons.cloud_off_outlined,
            color: demo ? AppColors.greenDark : AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              demo
                  ? 'Local demo registration. Data and document selections stay in this app session and are not uploaded.'
                  : 'Registration API is not connected. You may preview the form, but Submit will not create an application.',
              style: TextStyle(
                color: demo ? AppColors.greenDark : AppColors.danger,
                fontSize: 12.5,
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

class DriverRegistrationFailureCard extends StatelessWidget {
  final DriverRegistrationFailure failure;
  final VoidCallback? onRetry;

  const DriverRegistrationFailureCard({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        border: Border.all(color: AppColors.danger.withOpacity(.28)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failure.message,
              style: const TextStyle(
                color: AppColors.greenDark,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (failure.retryable && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class DriverReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const DriverReviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverDocumentCard extends StatelessWidget {
  final DriverRegistrationDocumentType type;
  final bool attached;
  final VoidCallback onPressed;

  const DriverDocumentCard({
    super.key,
    required this.type,
    required this.attached,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: attached ? const Color(0xFFF1F7F4) : AppColors.cream,
        border: Border.all(
          color:
              attached ? AppColors.success.withOpacity(.35) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: attached
                  ? AppColors.success.withOpacity(.12)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              attached ? Icons.check_rounded : Icons.description_outlined,
              color: attached ? AppColors.success : AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  attached ? 'Demo document selected' : type.helper,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPressed,
            child: Text(attached ? 'Remove' : 'Add'),
          ),
        ],
      ),
    );
  }
}
