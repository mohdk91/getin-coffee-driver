import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DriverSectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DriverSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class DriverSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  const DriverSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.borderColor = AppColors.border,
    this.radius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
    }

    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class DriverQuickActionTile extends StatelessWidget {
  final String label;
  final String? caption;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;

  const DriverQuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    this.caption,
    this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized ? AppColors.beige : AppColors.greenDark;
    final iconBackground =
        emphasized ? AppColors.white.withOpacity(.10) : AppColors.cream;

    return Material(
      color: emphasized ? AppColors.greenDark : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: emphasized ? AppColors.greenDark : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: emphasized ? AppColors.beige : AppColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 3),
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: emphasized
                        ? AppColors.white.withOpacity(.68)
                        : AppColors.muted,
                    fontSize: 9.8,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DriverStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? caption;

  const DriverStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return DriverSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: AppColors.green),
              ),
              const Spacer(),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DriverBranchThumbnail extends StatelessWidget {
  final String branchName;
  final double width;
  final double height;
  final double radius;

  const DriverBranchThumbnail({
    super.key,
    required this.branchName,
    this.width = 68,
    this.height = 68,
    this.radius = 14,
  });

  String? get _assetPath {
    final normalized = branchName.trim().toLowerCase();
    if (normalized.contains('san stefano')) {
      return 'assets/images/branches/getin_san_stefano.png';
    }
    if (normalized.contains('smouha')) {
      return 'assets/images/branches/getin_smouha.png';
    }
    if (normalized.contains('stanley')) {
      return 'assets/images/branches/getin_stanley.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPath;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      child: assetPath == null
          ? const Center(
              child: Icon(
                Icons.storefront_rounded,
                color: AppColors.green,
                size: 26,
              ),
            )
          : Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.storefront_rounded,
                  color: AppColors.green,
                  size: 26,
                ),
              ),
            ),
    );
  }
}

class DriverProgressCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String message;
  final double progress;
  final IconData icon;

  const DriverProgressCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.progress,
    this.icon = Icons.auto_graph_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.beige, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 8,
              backgroundColor: AppColors.white.withOpacity(.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            message,
            style: TextStyle(
              color: AppColors.white.withOpacity(.72),
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
