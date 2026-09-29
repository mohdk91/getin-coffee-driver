import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../home/domain/driver_home_models.dart';
import '../route/domain/driver_branch_route_models.dart';
import 'data/driver_start_delivery_repository.dart';
import 'domain/driver_start_delivery_models.dart';

class DriverStartDeliveryScreen extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary delivery;
  final DriverBranchRouteInfo route;
  final DriverStartDeliveryRepository? repository;
  final ValueChanged<DriverStartDeliveryReceipt>? onDeliveryStarted;

  const DriverStartDeliveryScreen({
    super.key,
    required this.config,
    required this.delivery,
    required this.route,
    this.repository,
    this.onDeliveryStarted,
  });

  @override
  State<DriverStartDeliveryScreen> createState() =>
      _DriverStartDeliveryScreenState();
}

class _DriverStartDeliveryScreenState extends State<DriverStartDeliveryScreen> {
  late final DriverStartDeliveryRepository _repository = widget.repository ??
      DriverStartDeliveryRepositoryFactory.create(widget.config);

  DriverStartDeliveryReceipt? _receipt;
  String? _errorMessage;
  bool _starting = false;

  bool get _isDemo => _repository.source == DriverStartDeliveryDataSource.demo;

  Future<void> _startDelivery() async {
    if (_starting || _receipt != null) return;

    setState(() {
      _starting = true;
      _errorMessage = null;
    });

    final result = await _repository.startDelivery(
      orderNumber: widget.delivery.orderNumber,
      latitude: widget.route.driverCoordinates.latitude,
      longitude: widget.route.driverCoordinates.longitude,
    );
    if (!mounted) return;

    setState(() {
      _starting = false;
      _receipt = result.receipt;
      _errorMessage = result.errorMessage;
    });

    if (result.receipt != null) {
      widget.onDeliveryStarted?.call(result.receipt!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Start Delivery')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
              children: [
                _DeliveryHeader(
                  delivery: widget.delivery,
                  started: _receipt != null,
                ),
                const SizedBox(height: 14),
                if (_isDemo) ...[
                  const _DemoStartNotice(),
                  const SizedBox(height: 14),
                ],
                _ReadinessCard(
                  branchName: widget.route.branchName,
                  destinationArea: widget.delivery.destinationArea,
                ),
                const SizedBox(height: 14),
                if (_errorMessage != null) ...[
                  _StartErrorCard(message: _errorMessage!),
                  const SizedBox(height: 14),
                ],
                if (_receipt == null)
                  _StartActionCard(
                    starting: _starting,
                    onStart: _starting ? null : _startDelivery,
                  )
                else
                  _StartReceiptCard(receipt: _receipt!),
                if (_receipt != null) ...[
                  const SizedBox(height: 14),
                  GetinActionButton(
                    label: 'Return to Driver App',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryHeader extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;
  final bool started;

  const _DeliveryHeader({required this.delivery, required this.started});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.orderNumber,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: started ? 'OUT FOR DELIVERY' : 'PICKED UP',
                tone: StatusTone.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            started
                ? 'Delivery started. The order is now in the delivery phase for this development session.'
                : 'Pickup is complete. Start the delivery only when you are ready to leave the branch.',
            style: const TextStyle(
              color: Color(0xFFE9E4D8),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStartNotice extends StatelessWidget {
  const _DemoStartNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBD8A3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Development demo. Start Delivery is stored only in this app session. Laravel and the Customer App are not updated.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final String branchName;
  final String destinationArea;

  const _ReadinessCard({
    required this.branchName,
    required this.destinationArea,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Ready to leave the branch?',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _ReadinessRow(
            icon: Icons.verified_outlined,
            text: 'Branch pickup has been verified and received.',
          ),
          const SizedBox(height: 10),
          const _ReadinessRow(
            icon: Icons.inventory_2_outlined,
            text:
                'Bags and handling instructions should be checked before departure.',
          ),
          const SizedBox(height: 10),
          _ReadinessRow(
            icon: Icons.storefront_outlined,
            text: 'Leaving $branchName for $destinationArea.',
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReadinessRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartActionCard extends StatelessWidget {
  final bool starting;
  final VoidCallback? onStart;

  const _StartActionCard({required this.starting, required this.onStart});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Start Delivery',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This is an explicit state change from picked up to out for delivery. It must eventually be acknowledged by Laravel before the Customer App changes state.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          GetinActionButton(
            label: starting ? 'Starting Delivery…' : 'Start Delivery',
            icon: starting ? Icons.hourglass_top_rounded : Icons.route_rounded,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _StartErrorCard extends StatelessWidget {
  final String message;

  const _StartErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3B7B7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartReceiptCard extends StatelessWidget {
  final DriverStartDeliveryReceipt receipt;

  const _StartReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final started = receipt.startedAt.toLocal();
    final time =
        '${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBDD6CA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 23),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Delivery started',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReceiptLine(label: 'Order', value: receipt.orderNumber),
          _ReceiptLine(label: 'Driver', value: receipt.driverId),
          _ReceiptLine(label: 'Started', value: time),
          _ReceiptLine(label: 'Audit', value: receipt.auditId),
          _ReceiptLine(
            label: 'Server',
            value: receipt.serverAcknowledged
                ? 'Acknowledged'
                : 'Demo only — not acknowledged by Laravel',
          ),
          const SizedBox(height: 9),
          const Text(
            'Customer delivery navigation is the next Driver task. No customer location/contact workflow has been started here.',
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

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 10.5,
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
