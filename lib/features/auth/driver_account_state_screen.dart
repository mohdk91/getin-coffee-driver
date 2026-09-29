import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import 'domain/driver_auth_models.dart';

class DriverAccountStateScreen extends StatelessWidget {
  final AppConfig config;
  final DriverAuthenticatedAccount account;
  final WidgetBuilder signInBuilder;

  const DriverAccountStateScreen({
    super.key,
    required this.config,
    required this.account,
    required this.signInBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(account.accessState);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: presentation.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        presentation.icon,
                        size: 34,
                        color: presentation.foreground,
                      ),
                    ),
                    const SizedBox(height: 20),
                    StatusPill(
                      label: presentation.status,
                      tone: presentation.pillType,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      presentation.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      presentation.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Driver ID: ${account.driverId}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: signInBuilder,
                            ),
                            (_) => false,
                          );
                        },
                        child: const Text('Back to Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This fallback screen is reserved for disabled authentication accounts. Verification states use the dedicated Driver Verification screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AccountStatePresentation _presentation(DriverAccessState state) {
    return switch (state) {
      DriverAccessState.pendingApproval => const _AccountStatePresentation(
          status: 'Pending',
          title: 'Approval Pending',
          message:
              'Your driver profile is still waiting for approval. You cannot receive delivery jobs until Getin operations approves the account.',
          icon: Icons.hourglass_top_rounded,
          foreground: AppColors.warning,
          background: Color(0xFFFFF3DF),
          pillType: StatusTone.warning,
        ),
      DriverAccessState.additionalInformationRequired =>
        const _AccountStatePresentation(
          status: 'Action Required',
          title: 'More Information Needed',
          message:
              'Getin operations needs additional information before driver access can be enabled.',
          icon: Icons.assignment_late_outlined,
          foreground: AppColors.info,
          background: Color(0xFFEAF2F8),
          pillType: StatusTone.info,
        ),
      DriverAccessState.rejected => const _AccountStatePresentation(
          status: 'Rejected',
          title: 'Driver Access Rejected',
          message:
              'This driver application is not approved for delivery access. Contact Getin operations if you need clarification.',
          icon: Icons.block_rounded,
          foreground: AppColors.danger,
          background: Color(0xFFFFECEC),
          pillType: StatusTone.danger,
        ),
      DriverAccessState.suspended => const _AccountStatePresentation(
          status: 'Suspended',
          title: 'Account Suspended',
          message:
              'Driver access is temporarily suspended. Delivery jobs remain unavailable until operations restores access.',
          icon: Icons.pause_circle_outline_rounded,
          foreground: AppColors.danger,
          background: Color(0xFFFFECEC),
          pillType: StatusTone.danger,
        ),
      DriverAccessState.disabled => const _AccountStatePresentation(
          status: 'Disabled',
          title: 'Account Not Active',
          message:
              'This driver account is not active. Sign in with another account or contact Getin operations.',
          icon: Icons.lock_outline_rounded,
          foreground: AppColors.danger,
          background: Color(0xFFFFECEC),
          pillType: StatusTone.danger,
        ),
      DriverAccessState.active => const _AccountStatePresentation(
          status: 'Active',
          title: 'Driver Access Active',
          message: 'This account is active.',
          icon: Icons.check_circle_outline_rounded,
          foreground: AppColors.success,
          background: Color(0xFFEAF5EF),
          pillType: StatusTone.success,
        ),
    };
  }
}

class _AccountStatePresentation {
  final String status;
  final String title;
  final String message;
  final IconData icon;
  final Color foreground;
  final Color background;
  final StatusTone pillType;

  const _AccountStatePresentation({
    required this.status,
    required this.title,
    required this.message,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.pillType,
  });
}
