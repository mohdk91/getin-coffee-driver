import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum WarningBannerTone { offline, gps, info }

class ConnectivityBanner extends StatelessWidget {
  final WarningBannerTone tone;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ConnectivityBanner({
    super.key,
    required this.tone,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (tone) {
      WarningBannerTone.offline => Icons.wifi_off_rounded,
      WarningBannerTone.gps => Icons.location_off_rounded,
      WarningBannerTone.info => Icons.info_outline_rounded,
    };
    final foreground = tone == WarningBannerTone.offline
        ? AppColors.danger
        : tone == WarningBannerTone.gps
            ? AppColors.warning
            : AppColors.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: foreground.withOpacity(.08),
        border: Border.all(color: foreground.withOpacity(.26)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: foreground, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(message,
                    style: const TextStyle(
                        color: AppColors.muted, height: 1.35, fontSize: 12)),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
