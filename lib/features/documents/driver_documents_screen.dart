import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import 'data/driver_documents_repository.dart';
import 'domain/driver_document_models.dart';

class DriverDocumentsScreen extends StatefulWidget {
  final AppConfig config;
  final DriverDocumentsRepository? repository;
  final Future<String?> Function()? replacementFileSelector;

  const DriverDocumentsScreen({
    super.key,
    required this.config,
    this.repository,
    this.replacementFileSelector,
  });

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  late final DriverDocumentsRepository _repository = widget.repository ??
      DriverDocumentsRepositoryFactory.create(widget.config);

  List<DriverDocumentSnapshot>? _documents;
  String? _errorMessage;
  bool _loading = true;
  String? _uploadingDocumentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _repository.loadDocuments();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _documents = result.documents;
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _startReplacement(DriverDocumentSnapshot document) async {
    String? fileName;
    try {
      if (widget.replacementFileSelector != null) {
        fileName = await widget.replacementFileSelector!();
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
          allowMultiple: false,
        );
        fileName = result?.files.single.name;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not open the document picker. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted || fileName == null) return;

    setState(() => _uploadingDocumentId = document.id);
    final result = await _repository.uploadReplacement(
      DriverDocumentReplacementRequest(
        documentId: document.id,
        fileName: fileName,
      ),
    );
    if (!mounted) return;

    setState(() {
      _uploadingDocumentId = null;
      final updated = result.document;
      if (updated != null && _documents != null) {
        _documents = [
          for (final item in _documents!)
            if (item.id == updated.id) updated else item,
        ];
      }
    });

    final message = result.isSuccess
        ? _repository.source == DriverDocumentDataSource.demo
            ? 'Replacement selected and submitted for review • DEMO'
            : 'Replacement submitted for review.'
        : result.errorMessage ?? 'Could not submit replacement.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _documents == null) {
      return const AppLoadingState(label: 'Loading documents…');
    }

    final documents = _documents;
    if (documents == null) {
      return AppStateView.error(
        title: 'Documents unavailable',
        message: _errorMessage ?? 'Could not load driver documents.',
        onRetry: _load,
      );
    }

    final now = DateTime.now();
    final warningCount =
        documents.where((item) => item.hasExpiryWarningAt(now)).length;
    final pendingCount = documents
        .where(
          (item) =>
              item.approvalState == DriverDocumentApprovalState.pendingReview,
        )
        .length;
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const PageStorageKey<String>('driver-documents-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 8, padding, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Approval, expiry and replacement status for your driver records.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_repository.source == DriverDocumentDataSource.demo) ...[
                  const SizedBox(width: 10),
                  const StatusPill(
                    label: 'DEMO',
                    tone: StatusTone.info,
                    icon: Icons.science_outlined,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            _DocumentSummaryCard(
              total: documents.length,
              warningCount: warningCount,
              pendingCount: pendingCount,
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < documents.length; index++) ...[
              _DocumentCard(
                document: documents[index],
                now: now,
                uploading: _uploadingDocumentId == documents[index].id,
                onUpload: documents[index].replacementAllowed
                    ? () => _startReplacement(documents[index])
                    : null,
              ),
              if (index != documents.length - 1) const SizedBox(height: 12),
            ],
            if (_repository.source == DriverDocumentDataSource.demo) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.info.withOpacity(.18)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Development document records are local demo data. You can choose a PDF/JPG/PNG replacement from the device, but demo mode stores only its file name and review state locally; no file is transmitted. Production files, approval states and expiry policies must come from Laravel.',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentSummaryCard extends StatelessWidget {
  final int total;
  final int warningCount;
  final int pendingCount;

  const _DocumentSummaryCard({
    required this.total,
    required this.warningCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'Records',
              value: '$total',
              icon: Icons.folder_copy_outlined,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryMetric(
              label: 'Expiry alerts',
              value: '$warningCount',
              icon: Icons.event_busy_outlined,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryMetric(
              label: 'In review',
              value: '$pendingCount',
              icon: Icons.fact_check_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.beige),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.beige,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.white.withOpacity(.15),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DriverDocumentSnapshot document;
  final DateTime now;
  final bool uploading;
  final VoidCallback? onUpload;

  const _DocumentCard({
    required this.document,
    required this.now,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final expiryState = document.expiryStateAt(now);
    final days = document.daysUntilExpiry(now);

    return Container(
      key: Key('document-card-${document.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconFor(document.type),
                  color: AppColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.type.label,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document.type.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ApprovalPill(state: document.approvalState),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _DocumentDetailRow(
            label: 'Reference',
            value: document.referenceLabel,
          ),
          const SizedBox(height: 9),
          _DocumentDetailRow(
            label: 'Expiry date',
            value: document.expiryDate == null
                ? 'Not applicable'
                : _formatDate(document.expiryDate!),
            valueKey: Key('document-expiry-${document.id}'),
          ),
          const SizedBox(height: 9),
          _DocumentDetailRow(
            label: 'Expiry status',
            value: _expiryLabel(expiryState, days),
          ),
          if (document.hasExpiryWarningAt(now)) ...[
            const SizedBox(height: 12),
            _ExpiryWarning(document: document, days: days),
          ],
          if (document.replacementFileName != null) ...[
            const SizedBox(height: 12),
            Container(
              key: Key('document-replacement-${document.id}'),
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(.16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.upload_file_outlined,
                    color: AppColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replacement: ${document.replacementFileName}\nSubmitted for review',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onUpload != null) ...[
            const SizedBox(height: 14),
            GetinActionButton(
              label: uploading ? 'Submitting…' : 'Upload replacement',
              icon: Icons.upload_file_outlined,
              secondary: true,
              onPressed: uploading ? null : onUpload,
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(DriverDocumentType type) {
    return switch (type) {
      DriverDocumentType.identity => Icons.badge_outlined,
      DriverDocumentType.driverLicense => Icons.credit_card_outlined,
      DriverDocumentType.vehicleRegistration => Icons.description_outlined,
      DriverDocumentType.insurance => Icons.shield_outlined,
    };
  }

  String _expiryLabel(DriverDocumentExpiryState state, int? days) {
    return switch (state) {
      DriverDocumentExpiryState.valid => 'Valid',
      DriverDocumentExpiryState.expiringSoon =>
        days == 0 ? 'Expires today' : 'Expires in $days days',
      DriverDocumentExpiryState.expired =>
        days == null ? 'Expired' : 'Expired ${days.abs()} days ago',
      DriverDocumentExpiryState.notApplicable => 'Not applicable',
    };
  }
}

class _ApprovalPill extends StatelessWidget {
  final DriverDocumentApprovalState state;

  const _ApprovalPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final tone = switch (state) {
      DriverDocumentApprovalState.approved => StatusTone.success,
      DriverDocumentApprovalState.pendingReview => StatusTone.warning,
      DriverDocumentApprovalState.rejected => StatusTone.danger,
      DriverDocumentApprovalState.expired => StatusTone.danger,
      DriverDocumentApprovalState.missing => StatusTone.neutral,
    };
    final icon = switch (state) {
      DriverDocumentApprovalState.approved => Icons.check_circle_outline,
      DriverDocumentApprovalState.pendingReview => Icons.schedule_outlined,
      DriverDocumentApprovalState.rejected => Icons.cancel_outlined,
      DriverDocumentApprovalState.expired => Icons.event_busy_outlined,
      DriverDocumentApprovalState.missing => Icons.help_outline_rounded,
    };
    return StatusPill(label: state.label, tone: tone, icon: icon);
  }
}

class _DocumentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Key? valueKey;

  const _DocumentDetailRow({
    required this.label,
    required this.value,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            key: valueKey,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpiryWarning extends StatelessWidget {
  final DriverDocumentSnapshot document;
  final int? days;

  const _ExpiryWarning({required this.document, required this.days});

  @override
  Widget build(BuildContext context) {
    final expired = (days ?? 0) < 0;
    final color = expired ? AppColors.danger : AppColors.warning;
    final message = expired
        ? 'This document is expired. Submit a replacement before taking new deliveries if required by Getin policy.'
        : 'Expiry warning: ${document.type.label} expires in ${days ?? 0} days. Prepare a replacement before it expires.';

    return Container(
      key: Key('document-expiry-warning-${document.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
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

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
