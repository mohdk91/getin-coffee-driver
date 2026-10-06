import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusTone { neutral, success, warning, danger, info }

class StatusPill extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  Color _foreground() {
    return switch (tone) {
      StatusTone.success => AppColors.success,
      StatusTone.warning => AppColors.warning,
      StatusTone.danger => AppColors.danger,
      StatusTone.info => AppColors.info,
      StatusTone.neutral => AppColors.greenDark,
    };
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _foreground();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 15),
              const SizedBox(width: 5),
            ],
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
