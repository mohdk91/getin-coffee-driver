import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/driver_v2_ui.dart';
import 'data/driver_profile_repository.dart';
import 'domain/driver_profile_models.dart';
import '../assignment/data/driver_assignment_repository.dart';
import '../assignment/driver_assignment_screen.dart';
import '../documents/data/driver_documents_repository.dart';
import '../documents/driver_documents_screen.dart';
import '../security/data/driver_security_repository.dart';
import '../security/driver_security_screen.dart';
import '../vehicle/data/driver_vehicle_repository.dart';
import '../vehicle/driver_vehicle_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final AppConfig config;
  final DriverProfileRepository? repository;

  const DriverProfileScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  late final DriverProfileRepository _repository =
      widget.repository ?? DriverProfileRepositoryFactory.create(widget.config);
  late final DriverVehicleRepository _vehicleRepository =
      DriverVehicleRepositoryFactory.create(widget.config);
  late final DriverAssignmentRepository _assignmentRepository =
      DriverAssignmentRepositoryFactory.create(widget.config);
  late final DriverDocumentsRepository _documentsRepository =
      DriverDocumentsRepositoryFactory.create(widget.config);
  late final DriverSecurityRepository _securityRepository =
      DriverSecurityRepositoryFactory.create(widget.config);

  DriverProfileSnapshot? _profile;
  String? _errorMessage;
  bool _loading = true;

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

    final result = await _repository.loadProfile();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _profile = result.profile;
      _errorMessage = result.errorMessage;
    });
  }

  void _openAssignment() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverAssignmentScreen(
          config: widget.config,
          repository: _assignmentRepository,
        ),
      ),
    );
  }

  void _openVehicle() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverVehicleScreen(
          config: widget.config,
          repository: _vehicleRepository,
        ),
      ),
    );
  }

  void _openDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverDocumentsScreen(
          config: widget.config,
          repository: _documentsRepository,
        ),
      ),
    );
  }

  void _openSecurity() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverSecurityScreen(
          config: widget.config,
          repository: _securityRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _profile == null) {
      return const AppLoadingState(label: 'Loading driver profile…');
    }

    final profile = _profile;
    if (profile == null) {
      return AppStateView.error(
        title: 'Profile unavailable',
        message: _errorMessage ?? 'Could not load the driver profile.',
        onRetry: _load,
      );
    }

    final padding = Responsive.horizontalPadding(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const PageStorageKey<String>('driver-profile-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 18, padding, 30),
        children: [
          const DriverSectionHeading(
            title: 'Driver Profile',
            subtitle: 'Your identity, work setup and account controls.',
          ),
          const SizedBox(height: 14),
          _ProfileHero(profile: profile),
          const SizedBox(height: 12),
          _ProfileOverviewStats(profile: profile),
          const SizedBox(height: 20),
          const DriverSectionHeading(
            title: 'Contact & identity',
            subtitle: 'The details linked to your driver account.',
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Account details',
            icon: Icons.badge_outlined,
            children: [
              _ProfileDetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: profile.phone,
              ),
              const _SectionDivider(),
              _ProfileDetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profile.email,
              ),
              const _SectionDivider(),
              _ProfileDetailRow(
                icon: Icons.fingerprint_rounded,
                label: 'Driver ID',
                value: profile.driverId,
                valueKey: const Key('profile-driver-id'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const DriverSectionHeading(
            title: 'Work setup',
            subtitle: 'Branch access, vehicle and compliance.',
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Current assignment',
            icon: Icons.hub_outlined,
            children: [
              _ProfileDetailRow(
                icon: Icons.map_outlined,
                label: 'Assigned region',
                value: profile.assignedRegion,
              ),
              const _SectionDivider(),
              _AssignedBranches(branches: profile.assignedBranches),
            ],
          ),
          const SizedBox(height: 10),
          _ProfileNavigationCard(
            key: const Key('profile-assignment-entry'),
            title: 'Branch & region',
            subtitle: 'Service areas, allowed branches and delivery radius.',
            icon: Icons.account_tree_outlined,
            onTap: _openAssignment,
          ),
          const SizedBox(height: 10),
          _ProfileNavigationCard(
            key: const Key('profile-vehicle-entry'),
            title: 'Vehicle',
            subtitle: 'Assigned vehicle and readiness status.',
            icon: Icons.two_wheeler_rounded,
            onTap: _openVehicle,
          ),
          const SizedBox(height: 10),
          _ProfileNavigationCard(
            key: const Key('profile-documents-entry'),
            title: 'Documents',
            subtitle: 'Approvals, expiry dates and replacements.',
            icon: Icons.folder_copy_outlined,
            onTap: _openDocuments,
          ),
          const SizedBox(height: 18),
          const DriverSectionHeading(
            title: 'Account & security',
            subtitle: 'Protect access to your driver account.',
          ),
          const SizedBox(height: 10),
          _ProfileNavigationCard(
            key: const Key('profile-security-entry'),
            title: 'Security',
            subtitle: 'Password, Driver PIN, devices, biometrics and logout.',
            icon: Icons.security_rounded,
            onTap: _openSecurity,
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final DriverProfileSnapshot profile;

  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DriverPhoto(profile: profile),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      key: const Key('profile-full-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _VerificationPill(status: profile.verificationStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: AppColors.beige,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Driver ID • ${profile.driverId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
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

class _ProfileOverviewStats extends StatelessWidget {
  final DriverProfileSnapshot profile;

  const _ProfileOverviewStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - (gap * 2)) / 3;
        return Row(
          children: [
            SizedBox(
              width: width,
              child: DriverStatTile(
                label: 'Status',
                value: profile.verificationStatus ==
                        DriverProfileVerificationStatus.approved
                    ? 'Verified'
                    : profile.verificationStatus.label,
                icon: Icons.verified_outlined,
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: width,
              child: DriverStatTile(
                label: 'Branches',
                value: '${profile.assignedBranches.length}',
                icon: Icons.storefront_outlined,
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: width,
              child: DriverStatTile(
                label: 'Region',
                value: 'Assigned',
                icon: Icons.map_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VerificationPill extends StatelessWidget {
  final DriverProfileVerificationStatus status;

  const _VerificationPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final foreground = switch (status) {
      DriverProfileVerificationStatus.approved => AppColors.success,
      DriverProfileVerificationStatus.pending => AppColors.warning,
      DriverProfileVerificationStatus.additionalInformationRequired =>
        AppColors.warning,
      DriverProfileVerificationStatus.rejected => AppColors.danger,
      DriverProfileVerificationStatus.suspended => AppColors.danger,
    };
    final icon = switch (status) {
      DriverProfileVerificationStatus.approved => Icons.verified_rounded,
      DriverProfileVerificationStatus.pending => Icons.schedule_rounded,
      DriverProfileVerificationStatus.additionalInformationRequired =>
        Icons.info_outline_rounded,
      DriverProfileVerificationStatus.rejected => Icons.cancel_outlined,
      DriverProfileVerificationStatus.suspended => Icons.block_rounded,
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverPhoto extends StatelessWidget {
  final DriverProfileSnapshot profile;

  const _DriverPhoto({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Driver photo',
      image: true,
      child: Container(
        key: const Key('driver-profile-photo'),
        width: 88,
        height: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cream,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.beige, width: 2),
        ),
        child: _photoContent(),
      ),
    );
  }

  Widget _photoContent() {
    final assetPath = profile.photoAssetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PhotoFallback(name: profile.fullName),
      );
    }

    final url = profile.photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PhotoFallback(name: profile.fullName),
      );
    }

    return _PhotoFallback(name: profile.fullName);
  }
}

class _PhotoFallback extends StatelessWidget {
  final String name;

  const _PhotoFallback({required this.name});

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: AppColors.greenDark,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
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
          Row(
            children: [
              Icon(icon, color: AppColors.green, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Key? valueKey;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.green, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                key: valueKey,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _AssignedBranches extends StatelessWidget {
  final List<String> branches;

  const _AssignedBranches({required this.branches});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.storefront_outlined,
            color: AppColors.green,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assigned branch(es)',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              if (branches.isEmpty)
                const Text(
                  'No branch assigned',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Wrap(
                  key: const Key('profile-assigned-branches'),
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final branch in branches)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          branch,
                          style: const TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileNavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileNavigationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                alignment: Alignment.center,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
