import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_delivery_exception_repository.dart';
import 'domain/driver_delivery_exception_models.dart';

class DriverDeliveryExceptionScreen extends StatefulWidget {
  final DriverActiveDeliverySummary delivery;
  final AppConfig config;
  final DriverDeliveryExceptionRepository? repository;
  final DriverDeliveryExceptionReceipt? existingReceipt;

  const DriverDeliveryExceptionScreen({
    super.key,
    required this.delivery,
    required this.config,
    this.repository,
    this.existingReceipt,
  });

  @override
  State<DriverDeliveryExceptionScreen> createState() =>
      _DriverDeliveryExceptionScreenState();
}

class _DriverDeliveryExceptionScreenState
    extends State<DriverDeliveryExceptionScreen> {
  late final DriverDeliveryExceptionRepository _repository =
      widget.repository ??
          DriverDeliveryExceptionRepositoryFactory.create(widget.config);
  final _noteController = TextEditingController();

  DriverDeliveryExceptionReason? _reason;
  DriverDeliveryExceptionReceipt? _receipt;
  String? _errorMessage;
  bool _submitting = false;

  bool get _isEditing => widget.existingReceipt != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReceipt;
    if (existing != null) {
      _reason = existing.reason;
      _noteController.text = existing.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting || _receipt != null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final existing = widget.existingReceipt;
    final typedNote = _noteController.text.trim();
    final note = typedNote.isEmpty && (existing?.note.trim().isNotEmpty ?? false)
        ? existing!.note
        : typedNote;

    final result = await _repository.reportException(
      apiOrderId: widget.delivery.apiOrderId,
      orderNumber: widget.delivery.orderNumber,
      reason: reason,
      note: note,
    );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _receipt = result.receipt;
      _errorMessage = result.isSuccess ? null : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Delivery Exception')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
          children: [
            if (receipt != null)
              _ExceptionReceipt(
                receipt: receipt,
                onDone: () => Navigator.of(context).pop(receipt),
              )
            else ...[
              _Header(delivery: widget.delivery),
              const SizedBox(height: 14),
              _SafetyNotice(
                  isDemo: _repository.source ==
                      DriverDeliveryExceptionDataSource.demo),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Update delivery issue' : 'What happened?',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...DriverDeliveryExceptionReason.values.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ReasonTile(
                    reason: reason,
                    selected: _reason == reason,
                    onTap: () => setState(() => _reason = reason),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Operational note (optional)',
                  hintText:
                      'Add only delivery-relevant details. Do not add unnecessary customer private information.',
                  alignLabelWithHint: true,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.danger.withOpacity(.20)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              GetinActionButton(
                label: _submitting
                    ? 'Confirming with Getin…'
                    : (_isEditing ? 'Update Exception' : 'Report Exception'),
                icon: Icons.report_problem_rounded,
                onPressed: _reason == null || _submitting ? null : _submit,
              ),
              const SizedBox(height: 10),
              if (_isEditing) ...[
                const Text(
                  'Existing issue details are loaded above. Updating the issue never unlocks verification or delivery completion.',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              const Text(
                'Reporting an exception never marks the order Delivered. Production must wait for Getin operations/server acknowledgement before changing the operational order state.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;

  const _Header({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery needs attention',
            style: TextStyle(
              color: AppColors.beige,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${delivery.orderNumber} • ${delivery.destinationArea}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  final bool isDemo;

  const _SafetyNotice({required this.isDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBD8A3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.warning, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDemo
                  ? 'Development mode: exception reports are stored locally only. Laravel and operations are not updated.'
                  : 'The order must remain unchanged until Getin acknowledges the exception.',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final DriverDeliveryExceptionReason reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.greenDark.withOpacity(.06) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.greenDark : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.greenDark : AppColors.muted,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reason.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExceptionReceipt extends StatelessWidget {
  final DriverDeliveryExceptionReceipt receipt;
  final VoidCallback onDone;

  const _ExceptionReceipt({required this.receipt, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem_rounded,
                  color: AppColors.warning, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Exception Recorded',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatusPill(
            label: receipt.isDemo ? 'ISSUE • DEMO' : 'ISSUE REPORTED',
            tone: StatusTone.warning,
          ),
          const SizedBox(height: 14),
          _ReceiptRow(label: 'Order', value: receipt.orderNumber),
          _ReceiptRow(label: 'Reason', value: receipt.reason.label),
          _ReceiptRow(
            label: 'Recommended state',
            value: receipt.recommendedOrderState,
          ),
          _ReceiptRow(
            label: 'GPS',
            value: receipt.latitude == null || receipt.longitude == null
                ? 'Not available'
                : '${receipt.latitude!.toStringAsFixed(5)}, ${receipt.longitude!.toStringAsFixed(5)}',
          ),
          _ReceiptRow(
            label: 'Server acknowledgement',
            value:
                receipt.serverAcknowledged ? 'Confirmed' : 'Not acknowledged',
          ),
          if (receipt.note.isNotEmpty)
            _ReceiptRow(label: 'Note', value: receipt.note),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBD8A3)),
            ),
            child: Text(
              receipt.reason == DriverDeliveryExceptionReason.returnToBranch
                  ? 'Return to branch is the recommended next action. Task #24 will formalize the delivery state transition.'
                  : 'The order is not Delivered. Keep the active delivery open until Getin operations resolves the exception.',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GetinActionButton(
            label: 'Back to Delivery',
            icon: Icons.arrow_back_rounded,
            secondary: true,
            onPressed: onDone,
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
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
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
