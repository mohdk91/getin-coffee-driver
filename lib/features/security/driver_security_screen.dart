import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/status_pill.dart';
import '../auth/driver_login_screen.dart';
import 'data/driver_security_repository.dart';
import 'domain/driver_security_models.dart';

class DriverSecurityScreen extends StatefulWidget {
  final AppConfig config;
  final DriverSecurityRepository? repository;
  final VoidCallback? onLoggedOut;

  const DriverSecurityScreen({
    super.key,
    required this.config,
    this.repository,
    this.onLoggedOut,
  });

  @override
  State<DriverSecurityScreen> createState() => _DriverSecurityScreenState();
}

class _DriverSecurityScreenState extends State<DriverSecurityScreen> {
  late final DriverSecurityRepository _repository = widget.repository ??
      DriverSecurityRepositoryFactory.create(widget.config);

  DriverSecuritySnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  bool _actionInProgress = false;

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

    final result = await _repository.loadSecurity();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _snapshot = result.snapshot;
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _changePassword() async {
    final values = await showModalBottomSheet<_PasswordValues>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (values == null || _actionInProgress) return;

    setState(() => _actionInProgress = true);
    final result = await _repository.changePassword(
      currentPassword: values.currentPassword,
      newPassword: values.newPassword,
    );
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    _showMessage(result.message ?? 'Password request completed.');
    if (result.success) await _load();
  }

  Future<void> _changePin() async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ChangePinSheet(),
    );
    if (pin == null || _actionInProgress) return;

    setState(() => _actionInProgress = true);
    final result = await _repository.setPin(pin: pin);
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    _showMessage(result.message ?? 'PIN request completed.');
    if (result.success) await _load();
  }

  Future<void> _revokeSession(DriverActiveSession session) async {
    if (_actionInProgress) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out this device?'),
        content: Text(
          'End the ${session.deviceName} session? The current phone will remain signed in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    final result = await _repository.revokeSession(session.id);
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    _showMessage(result.message ?? 'Session request completed.');
    if (result.success) await _load();
  }

  Future<void> _logout() async {
    if (_actionInProgress) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'This ends the current Driver App session on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('security-confirm-logout'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    final result = await _repository.logout();
    if (!mounted) return;
    setState(() => _actionInProgress = false);

    if (!result.success) {
      _showMessage(result.message ?? 'Could not log out.');
      return;
    }

    final callback = widget.onLoggedOut;
    if (callback != null) {
      callback();
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => DriverLoginScreen(config: widget.config),
      ),
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const Scaffold(
        body: AppLoadingState(label: 'Loading account security…'),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security')),
        body: AppStateView.error(
          title: 'Security unavailable',
          message: _errorMessage ?? 'Could not load account security.',
          onRetry: _load,
        ),
      );
    }

    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const PageStorageKey<String>('driver-security-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 18, padding, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account security',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Protect sign-in, review active devices and control this session.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_repository.source == DriverSecurityDataSource.demo)
                  const StatusPill(
                    label: 'DEMO',
                    tone: StatusTone.info,
                    icon: Icons.science_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SecurityHero(snapshot: snapshot),
            const SizedBox(height: 14),
            _SecurityActionCard(
              key: const Key('security-password-card'),
              icon: Icons.password_rounded,
              title: 'Password',
              subtitle: snapshot.passwordUpdatedAt == null
                  ? 'Password protection is enabled.'
                  : 'Protected • Last changed ${_shortDate(snapshot.passwordUpdatedAt!)}',
              actionLabel: 'Change',
              onTap: _actionInProgress ? null : _changePassword,
            ),
            const SizedBox(height: 12),
            _SecurityActionCard(
              key: const Key('security-pin-card'),
              icon: Icons.pin_outlined,
              title: 'Driver PIN',
              subtitle: snapshot.pinConfigured
                  ? '${snapshot.pinDigits}-digit PIN configured'
                  : 'No Driver PIN configured',
              actionLabel: snapshot.pinConfigured ? 'Change' : 'Set PIN',
              onTap: _actionInProgress ? null : _changePin,
            ),
            const SizedBox(height: 12),
            _BiometricCard(snapshot: snapshot),
            const SizedBox(height: 18),
            const _SectionHeading(
              title: 'Active sessions & devices',
              subtitle: 'Review where this Driver account is signed in.',
            ),
            const SizedBox(height: 10),
            if (snapshot.activeSessions.isEmpty)
              const _EmptySessionsCard()
            else
              ...snapshot.activeSessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SessionCard(
                    session: session,
                    disabled: _actionInProgress,
                    onRevoke: session.isCurrent
                        ? null
                        : () => _revokeSession(session),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            _AccountSecurityCard(snapshot: snapshot),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                key: const Key('security-logout'),
                onPressed: _actionInProgress ? null : _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (_repository.source == DriverSecurityDataSource.demo) ...[
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
                        'Test security data is local to this non-production build. Password, PIN, session and logout changes do not affect a live account.',
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

String _shortDate(DateTime value) {
  const months = <String>[
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class _SecurityHero extends StatelessWidget {
  final DriverSecuritySnapshot snapshot;

  const _SecurityHero({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final protected = snapshot.passwordProtected && snapshot.pinConfigured;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.1),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.beige.withOpacity(.22)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.beige,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protected ? 'Account protected' : 'Security setup needed',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${snapshot.activeSessions.length} active device${snapshot.activeSessions.length == 1 ? '' : 's'} • PIN ${snapshot.pinConfigured ? 'on' : 'off'}',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(.72),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  const _SecurityActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _BiometricCard extends StatelessWidget {
  final DriverSecuritySnapshot snapshot;

  const _BiometricCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('security-biometric-card'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: AppColors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biometric sign-in',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${snapshot.biometricReadiness.label}. Native device enrollment will be connected through the biometric gateway.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const StatusPill(
                  label: 'READY FOR INTEGRATION',
                  tone: StatusTone.info,
                  icon: Icons.architecture_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.greenDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final DriverActiveSession session;
  final bool disabled;
  final VoidCallback? onRevoke;

  const _SessionCard({
    required this.session,
    required this.disabled,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('security-session-${session.id}'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: session.isCurrent
                  ? AppColors.success.withOpacity(.09)
                  : AppColors.cream,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              session.isCurrent
                  ? Icons.smartphone_rounded
                  : Icons.devices_other_rounded,
              color: session.isCurrent ? AppColors.success : AppColors.green,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.deviceName,
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (session.isCurrent)
                      const StatusPill(
                        label: 'CURRENT',
                        tone: StatusTone.success,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.platform} • ${session.locationLabel}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.isCurrent
                      ? 'Current device • Active now'
                      : 'Active session • Last active ${_shortDate(session.lastActiveAt)}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!session.isCurrent) ...[
                  const SizedBox(height: 7),
                  TextButton.icon(
                    key: Key('security-revoke-${session.id}'),
                    onPressed: disabled ? null : onRevoke,
                    icon: const Icon(Icons.logout_rounded, size: 17),
                    label: const Text('Sign out device'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySessionsCard extends StatelessWidget {
  const _EmptySessionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No active sessions were returned.',
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}

class _AccountSecurityCard extends StatelessWidget {
  final DriverSecuritySnapshot snapshot;

  const _AccountSecurityCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('security-account-security-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: AppColors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Account security',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SecurityCheck(
            label: 'Password protection',
            enabled: snapshot.passwordProtected,
          ),
          const SizedBox(height: 7),
          _SecurityCheck(
            label: 'Driver PIN',
            enabled: snapshot.pinConfigured,
          ),
          const SizedBox(height: 7),
          const _SecurityCheck(
            label: 'Biometric gateway boundary',
            enabled: true,
          ),
        ],
      ),
    );
  }
}

class _SecurityCheck extends StatelessWidget {
  final String label;
  final bool enabled;

  const _SecurityCheck({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          enabled ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          color: enabled ? AppColors.success : AppColors.warning,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordValues {
  final String currentPassword;
  final String newPassword;

  const _PasswordValues({
    required this.currentPassword,
    required this.newPassword,
  });
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _PasswordValues(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Change password',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Test password: Driver123!',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('security-current-password'),
              controller: _currentController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your current password.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('security-new-password'),
              controller: _newController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) => (value ?? '').length < 8
                  ? 'Use at least 8 characters.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('security-confirm-password'),
              controller: _confirmController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => value != _newController.text
                  ? 'Passwords do not match.'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('security-submit-password'),
                onPressed: _submit,
                child: const Text('Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet();

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_pinController.text);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Driver PIN',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Use 4 to 6 digits. This is separate from customer delivery verification codes.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('security-pin'),
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'New PIN'),
              validator: (value) => RegExp(r'^\d{4,6}$').hasMatch(value ?? '')
                  ? null
                  : 'Enter 4 to 6 digits.',
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('security-confirm-pin'),
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  value != _pinController.text ? 'PINs do not match.' : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('security-submit-pin'),
                onPressed: _submit,
                child: const Text('Save PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
