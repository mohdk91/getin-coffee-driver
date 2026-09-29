import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ActiveDeliveryBar extends StatelessWidget {
  final String orderNumber;
  final String status;
  final VoidCallback onTap;

  const ActiveDeliveryBar({
    super.key,
    required this.orderNumber,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: AppColors.beige),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active delivery • $orderNumber',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900),
                      ),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.beige, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.beige),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
