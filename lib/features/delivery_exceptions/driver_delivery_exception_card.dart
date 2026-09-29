import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_delivery_exception_repository.dart';
import 'domain/driver_delivery_exception_models.dart';
import 'driver_delivery_exception_screen.dart';

class DriverDeliveryExceptionCard extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;
  final AppConfig config;
  final DriverDeliveryExceptionRepository? repository;
  final DriverDeliveryExceptionReceipt? receipt;
  final ValueChanged<DriverDeliveryExceptionReceipt>? onReported;
  final bool deliveryCompleted;

  const DriverDeliveryExceptionCard({
    super.key,
    required this.delivery,
    required this.config,
    this.repository,
    this.receipt,
    this.onReported,
    this.deliveryCompleted = false,
  });

  Future<void> _open(BuildContext context) async {
    final result =
        await Navigator.of(context).push<DriverDeliveryExceptionReceipt>(
      MaterialPageRoute<DriverDeliveryExceptionReceipt>(
        builder: (_) => DriverDeliveryExceptionScreen(
          delivery: delivery,
          config: config,
          repository: repository,
        ),
      ),
    );
    if (result != null) onReported?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final current = receipt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: current == null
              ? AppColors.border
              : AppColors.warning.withOpacity(.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                current == null
                    ? Icons.report_problem_outlined
                    : Icons.warning_amber_rounded,
                color:
                    current == null ? AppColors.greenDark : AppColors.warning,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Delivery exception',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            current == null
                ? 'Report a delivery problem without falsely completing the order.'
                : '${current.reason.label} has been recorded. This delivery remains non-delivered.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (current != null) ...[
            const SizedBox(height: 12),
            StatusPill(
              label: current.isDemo ? 'ISSUE • DEMO' : 'ISSUE REPORTED',
              tone: StatusTone.warning,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          const SizedBox(height: 14),
          GetinActionButton(
            label: current == null
                ? 'Report Delivery Issue'
                : 'View / Update Issue',
            icon: Icons.report_gmailerrorred_rounded,
            secondary: true,
            onPressed: deliveryCompleted ? null : () => _open(context),
          ),
        ],
      ),
    );
  }
}
