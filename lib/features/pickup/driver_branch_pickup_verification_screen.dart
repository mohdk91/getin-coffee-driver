import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/offline/driver_offline_safety.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/getin_text_field.dart';
import '../../core/widgets/status_pill.dart';
import '../route/domain/driver_branch_route_models.dart';
import 'data/driver_branch_pickup_repository.dart';
import 'domain/driver_branch_pickup_models.dart';

class DriverBranchPickupVerificationScreen extends StatefulWidget {
  final AppConfig config;
  final DriverBranchRouteInfo route;
  final DriverBranchPickupRepository? repository;
  final ValueChanged<DriverBranchPickupReceipt>? onPickupReceived;
  final DriverCriticalActionGate? criticalActionGate;

  const DriverBranchPickupVerificationScreen({
    super.key,
    required this.config,
    required this.route,
    this.repository,
    this.onPickupReceived,
    this.criticalActionGate,
  });

  @override
  State<DriverBranchPickupVerificationScreen> createState() =>
      _DriverBranchPickupVerificationScreenState();
}

class _DriverBranchPickupVerificationScreenState
    extends State<DriverBranchPickupVerificationScreen> {
  late final DriverBranchPickupRepository _repository = widget.repository ??
      DriverBranchPickupRepositoryFactory.create(widget.config);
  final TextEditingController _tokenController = TextEditingController();

  DriverBranchPickupVerification? _verification;
  DriverBranchPickupReceipt? _receipt;
  String? _errorMessage;
  bool _verifying = false;
  bool _receiving = false;

  bool get _isDemo => _repository.source == DriverBranchPickupDataSource.demo;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Enter the branch pickup token first.');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    final result = await _repository.verifyToken(
      apiOrderId: widget.route.apiOrderId,
      orderNumber: widget.route.orderNumber,
      branchName: widget.route.branchName,
      token: token,
    );
    if (!mounted) return;

    setState(() {
      _verifying = false;
      _verification = result.verification;
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _scanQr() async {
    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    final result = await _repository.scanBranchQr(
      apiOrderId: widget.route.apiOrderId,
      orderNumber: widget.route.orderNumber,
      branchName: widget.route.branchName,
    );
    if (!mounted) return;

    setState(() {
      _verifying = false;
      _verification = result.verification;
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _confirmReceived() async {
    final verification = _verification;
    if (verification == null) return;
    if (!driverCriticalActionAllowed(widget.criticalActionGate)) {
      setState(() {
        _errorMessage = DriverCriticalAction.receivedFromBranch.offlineMessage;
      });
      return;
    }

    setState(() {
      _receiving = true;
      _errorMessage = null;
    });

    final result = await _repository.confirmReceived(
      apiOrderId: widget.route.apiOrderId,
      verification: verification,
      latitude: widget.route.driverCoordinates.latitude,
      longitude: widget.route.driverCoordinates.longitude,
    );
    if (!mounted) return;

    setState(() {
      _receiving = false;
      _receipt = result.receipt;
      _errorMessage = result.errorMessage;
    });

    if (result.receipt != null) {
      widget.onPickupReceived?.call(result.receipt!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Branch Pickup')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                16,
                Responsive.horizontalPadding(context),
                32,
              ),
              children: [
                _PickupProgress(receipt: _receipt, verification: _verification),
                const SizedBox(height: 14),
                if (_isDemo) ...[
                  const _DemoPickupNotice(),
                  const SizedBox(height: 14),
                ],
                _OrderBranchCard(route: widget.route),
                const SizedBox(height: 14),
                if (_receipt == null) ...[
                  _VerificationCard(
                    tokenController: _tokenController,
                    verification: _verification,
                    verifying: _verifying,
                    errorMessage: _errorMessage,
                    isDemo: _isDemo,
                    onVerifyToken: _verifyToken,
                    onScanQr: _scanQr,
                  ),
                  const SizedBox(height: 14),
                  _ReceivePickupCard(
                    verification: _verification,
                    receiving: _receiving,
                    onConfirm: _verification == null || _receiving
                        ? null
                        : _confirmReceived,
                  ),
                ] else ...[
                  _PickupReceiptCard(receipt: _receipt!),
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

class _PickupProgress extends StatelessWidget {
  final DriverBranchPickupVerification? verification;
  final DriverBranchPickupReceipt? receipt;

  const _PickupProgress({required this.verification, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _ProgressStep(
              number: '1',
              label: 'Arrived',
              complete: true,
            ),
          ),
          _ProgressLine(active: verification != null),
          Expanded(
            child: _ProgressStep(
              number: '2',
              label: 'Verified',
              complete: verification != null,
            ),
          ),
          _ProgressLine(active: receipt != null),
          Expanded(
            child: _ProgressStep(
              number: '3',
              label: 'Received',
              complete: receipt != null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String number;
  final String label;
  final bool complete;

  const _ProgressStep({
    required this.number,
    required this.label,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: complete ? AppColors.beige : const Color(0xFF29443C),
            shape: BoxShape.circle,
          ),
          child: complete
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.greenDark,
                )
              : Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: complete ? AppColors.beige : const Color(0xFFB8C3BF),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final bool active;

  const _ProgressLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 19),
      color: active ? AppColors.beige : const Color(0xFF355047),
    );
  }
}

class _DemoPickupNotice extends StatelessWidget {
  const _DemoPickupNotice();

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
              'Development demo. QR scanning and pickup acknowledgement are simulated locally. Laravel order status is not changed.',
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

class _OrderBranchCard extends StatelessWidget {
  final DriverBranchRouteInfo route;

  const _OrderBranchCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(.32),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.orderNumber,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  route.branchName,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  route.branchAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const StatusPill(label: 'AT BRANCH', tone: StatusTone.info),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final TextEditingController tokenController;
  final DriverBranchPickupVerification? verification;
  final bool verifying;
  final String? errorMessage;
  final bool isDemo;
  final VoidCallback onVerifyToken;
  final VoidCallback onScanQr;

  const _VerificationCard({
    required this.tokenController,
    required this.verification,
    required this.verifying,
    required this.errorMessage,
    required this.isDemo,
    required this.onVerifyToken,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify the branch handoff',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Verify this order with the branch before taking custody of the bags.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          GetinActionButton(
            label: verifying ? 'Checking QR…' : 'Scan Branch QR',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: verifying || verification != null ? null : onScanQr,
          ),
          if (isDemo) ...[
            const SizedBox(height: 7),
            const Text(
              'Demo: this simulates a valid branch QR scan. Camera integration is not being presented as live.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
          ),
          GetinTextField(
            label: 'Branch pickup token',
            hint: isDemo ? 'Demo token: 2468' : 'Enter token from branch staff',
            controller: tokenController,
            keyboardType: TextInputType.number,
            enabled: !verifying && verification == null,
            prefixIcon: const Icon(Icons.password_rounded),
          ),
          const SizedBox(height: 10),
          GetinActionButton(
            label: verifying ? 'Verifying…' : 'Verify Token',
            icon: Icons.verified_outlined,
            secondary: true,
            onPressed: verifying || verification != null ? null : onVerifyToken,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              icon: Icons.error_outline_rounded,
              message: errorMessage!,
              color: AppColors.danger,
            ),
          ],
          if (verification != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              icon: Icons.verified_rounded,
              message:
                  'Pickup verified with ${verification!.method.label}. You may now confirm receipt from the branch.',
              color: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceivePickupCard extends StatelessWidget {
  final DriverBranchPickupVerification? verification;
  final bool receiving;
  final VoidCallback? onConfirm;

  const _ReceivePickupCard({
    required this.verification,
    required this.receiving,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final ready = verification != null;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ready ? AppColors.white : const Color(0xFFF0EEE8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ready ? Icons.inventory_2_outlined : Icons.lock_outline_rounded,
                color: ready ? AppColors.green : AppColors.muted,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Take custody of the order',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ready
                          ? 'Confirm only after branch staff hands you the complete order.'
                          : 'Received from Branch stays locked until order verification succeeds.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GetinActionButton(
            label: receiving ? 'Confirming…' : 'Received from Branch',
            icon: Icons.inventory_rounded,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _PickupReceiptCard extends StatelessWidget {
  final DriverBranchPickupReceipt receipt;

  const _PickupReceiptCard({required this.receipt});

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 27),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pickup recorded',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            receipt.isDemo
                ? 'Development simulation only. This proves the custody workflow but did not update Laravel.'
                : 'Getin confirmed that the driver received the order from the branch.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _AuditRow(label: 'Order', value: receipt.orderNumber),
          _AuditRow(label: 'Branch', value: receipt.branchName),
          _AuditRow(label: 'Driver', value: receipt.driverId),
          _AuditRow(
            label: 'Verification',
            value: receipt.verificationMethod.label,
          ),
          _AuditRow(label: 'Verified', value: _formatTime(receipt.verifiedAt)),
          _AuditRow(label: 'Received', value: _formatTime(receipt.receivedAt)),
          _AuditRow(label: 'Audit ID', value: receipt.auditId),
          _AuditRow(
            label: 'GPS',
            value: receipt.latitude == null || receipt.longitude == null
                ? 'Not available'
                : '${receipt.latitude!.toStringAsFixed(5)}, ${receipt.longitude!.toStringAsFixed(5)}',
          ),
          _AuditRow(
            label: 'Server acknowledgement',
            value: receipt.serverAcknowledged
                ? 'Confirmed'
                : 'Demo only — not acknowledged by Laravel',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _AuditRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
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

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _InlineMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
