import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import '../foundation/driver_foundation_shell.dart';
import 'data/driver_verification_repository.dart';
import 'domain/driver_verification_models.dart';

class DriverVerificationStatusScreen extends StatefulWidget {
  final AppConfig config;
  final DriverVerificationProfile initialProfile;
  final DriverVerificationRepository repository;
  final WidgetBuilder signInBuilder;

  const DriverVerificationStatusScreen({
    super.key,
    required this.config,
    required this.initialProfile,
    required this.repository,
    required this.signInBuilder,
  });

  @override
  State<DriverVerificationStatusScreen> createState() =>
      _DriverVerificationStatusScreenState();
}

class _DriverVerificationStatusScreenState
    extends State<DriverVerificationStatusScreen> {
  late DriverVerificationProfile _profile;
  DriverVerificationFailure? _failure;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _failure = null;
    });

    final result = await widget.repository.refreshStatus(_profile);
    if (!mounted) return;

    setState(() {
      _refreshing = false;
      if (result.isSuccess) {
        _profile = result.data!;
      } else {
        _failure = result.failure;
      }
    });
  }

  void _enterDriverApp() {
    if (!_profile.canReceiveJobs) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => DriverFoundationShell(config: widget.config),
      ),
      (_) => false,
    );
  }

  void _backToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: widget.signInBuilder),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(_profile.state);
    final compact = MediaQuery.sizeOf(context).width < 380;
    final horizontal = compact ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.greenDark,
        foregroundColor: AppColors.beige,
        title: const Text(
          'Verification Status',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            tooltip: 'Refresh status',
            icon: _refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.beige,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28),
              children: [
                if (widget.repository.source == DriverVerificationSource.demo)
                  const _DemoBanner(),
                if (widget.repository.source == DriverVerificationSource.demo)
                  const SizedBox(height: 16),
                _StatusCard(
                  profile: _profile,
                  presentation: presentation,
                ),
                const SizedBox(height: 16),
                _AccessRuleCard(canReceiveJobs: _profile.canReceiveJobs),
                if (_profile.requestedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RequestedInformationCard(items: _profile.requestedItems),
                ],
                if (_failure != null) ...[
                  const SizedBox(height: 16),
                  _FailureCard(failure: _failure!, onRetry: _refresh),
                ],
                const SizedBox(height: 18),
                if (_profile.canReceiveJobs)
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _enterDriverApp,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Enter Driver App'),
                    ),
                  )
                else
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _refreshing ? null : _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh Status'),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _backToSignIn,
                    child: const Text('Back to Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final DriverVerificationProfile profile;
  final _VerificationPresentation presentation;

  const _StatusCard({required this.profile, required this.presentation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0D211C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: presentation.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.foreground,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      label: presentation.status,
                      tone: presentation.tone,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      presentation.title,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            presentation.message,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _MetaRow(label: 'Driver', value: profile.displayName),
          const SizedBox(height: 10),
          _MetaRow(label: 'Driver ID', value: profile.driverId),
          if (profile.applicationId != null) ...[
            const SizedBox(height: 10),
            _MetaRow(label: 'Application', value: profile.applicationId!),
          ],
          const SizedBox(height: 10),
          _MetaRow(
              label: 'Last checked', value: _formatTime(profile.updatedAt)),
        ],
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessRuleCard extends StatelessWidget {
  final bool canReceiveJobs;

  const _AccessRuleCard({required this.canReceiveJobs});

  @override
  Widget build(BuildContext context) {
    final foreground = canReceiveJobs ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: foreground.withOpacity(.08),
        border: Border.all(color: foreground.withOpacity(.20)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            canReceiveJobs ? Icons.verified_rounded : Icons.lock_clock_rounded,
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canReceiveJobs
                  ? 'Approved drivers may enter the Driver app and can become eligible for delivery jobs.'
                  : 'Delivery access is locked. Only an approved driver may receive delivery jobs.',
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestedInformationCard extends StatelessWidget {
  final List<String> items;

  const _RequestedInformationCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information requested',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right_rounded,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          const Text(
            'The correction/upload action will use the Laravel application API later. This Task #5 demo does not pretend an update was submitted.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  final DriverVerificationFailure failure;
  final VoidCallback onRetry;

  const _FailureCard({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        border: Border.all(color: AppColors.danger.withOpacity(.20)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failure.message,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (failure.retryable) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.greenDark, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Local demo verification. Refresh reads demo state only; it does not contact Laravel or change a real driver account.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 12,
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

_VerificationPresentation _presentation(DriverVerificationState state) {
  return switch (state) {
    DriverVerificationState.pending => const _VerificationPresentation(
        status: 'Pending',
        title: 'Application under review',
        message:
            'Getin operations is reviewing your identity, driving licence, vehicle, documents and service area. Delivery access remains locked until approval.',
        icon: Icons.hourglass_top_rounded,
        foreground: AppColors.warning,
        background: Color(0xFFFFF3DF),
        tone: StatusTone.warning,
      ),
    DriverVerificationState.approved => const _VerificationPresentation(
        status: 'Approved',
        title: 'You are approved to drive',
        message:
            'Your driver profile is approved. You may enter the Driver app; later eligibility checks still depend on availability, GPS, region, branch, vehicle and active-order capacity.',
        icon: Icons.verified_rounded,
        foreground: AppColors.success,
        background: Color(0xFFEAF5EF),
        tone: StatusTone.success,
      ),
    DriverVerificationState.rejected => const _VerificationPresentation(
        status: 'Rejected',
        title: 'Application not approved',
        message:
            'The current application is not approved for delivery access. Delivery jobs remain unavailable. Contact Getin operations when a real backend/support channel is connected.',
        icon: Icons.block_rounded,
        foreground: AppColors.danger,
        background: Color(0xFFFFECEC),
        tone: StatusTone.danger,
      ),
    DriverVerificationState.additionalInformationRequired =>
      const _VerificationPresentation(
        status: 'Action Required',
        title: 'More information is needed',
        message:
            'Getin operations needs additional information before it can finish the review. Delivery access remains locked until the requested items are accepted.',
        icon: Icons.assignment_late_outlined,
        foreground: AppColors.info,
        background: Color(0xFFEAF2F8),
        tone: StatusTone.info,
      ),
    DriverVerificationState.suspended => const _VerificationPresentation(
        status: 'Suspended',
        title: 'Driver access suspended',
        message:
            'This approved driver profile is currently suspended. The account cannot receive delivery jobs until Getin operations restores driver access.',
        icon: Icons.pause_circle_outline_rounded,
        foreground: AppColors.danger,
        background: Color(0xFFFFECEC),
        tone: StatusTone.danger,
      ),
  };
}

class _VerificationPresentation {
  final String status;
  final String title;
  final String message;
  final IconData icon;
  final Color foreground;
  final Color background;
  final StatusTone tone;

  const _VerificationPresentation({
    required this.status,
    required this.title,
    required this.message,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.tone,
  });
}
