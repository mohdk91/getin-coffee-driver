import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/getin_logo.dart';
import '../domain/driver_auth_models.dart';

class DriverAuthHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const DriverAuthHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3B32), AppColors.greenDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GetinLogoMark(size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.beige.withOpacity(.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: 13.5,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class DriverAuthModeBanner extends StatelessWidget {
  final DriverAuthSource source;
  final VoidCallback? onDemoHelp;

  const DriverAuthModeBanner({
    super.key,
    required this.source,
    this.onDemoHelp,
  });

  @override
  Widget build(BuildContext context) {
    final demo = source == DriverAuthSource.demo;
    final background = demo ? const Color(0xFFF0E8D4) : const Color(0xFFFFECEC);
    final foreground = demo ? AppColors.greenDark : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            demo ? Icons.science_outlined : Icons.cloud_off_outlined,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              demo
                  ? 'Local demo authentication. No SMS, email, or backend request is sent.'
                  : 'Authentication API is not connected. Login actions will not be marked successful.',
              style: TextStyle(
                color: foreground,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (demo && onDemoHelp != null) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: onDemoHelp,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.greenDark,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Demo help'),
            ),
          ],
        ],
      ),
    );
  }
}

class DriverAuthErrorCard extends StatelessWidget {
  final DriverAuthFailure failure;
  final VoidCallback? onRetry;

  const DriverAuthErrorCard({
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
          if (failure.retryable && onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class DriverAuthSectionCard extends StatelessWidget {
  final Widget child;

  const DriverAuthSectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D211C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
