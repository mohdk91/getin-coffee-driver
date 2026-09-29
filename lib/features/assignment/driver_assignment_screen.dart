import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/status_pill.dart';
import 'data/driver_assignment_repository.dart';
import 'domain/driver_assignment_models.dart';

class DriverAssignmentScreen extends StatefulWidget {
  final AppConfig config;
  final DriverAssignmentRepository? repository;

  const DriverAssignmentScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverAssignmentScreen> createState() => _DriverAssignmentScreenState();
}

class _DriverAssignmentScreenState extends State<DriverAssignmentScreen> {
  late final DriverAssignmentRepository _repository = widget.repository ??
      DriverAssignmentRepositoryFactory.create(widget.config);

  DriverAssignmentSnapshot? _assignment;
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

    final result = await _repository.loadAssignment();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _assignment = result.assignment;
      _errorMessage = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _assignment == null) {
      return const Scaffold(
        body: AppLoadingState(label: 'Loading operational assignment…'),
      );
    }

    final assignment = _assignment;
    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Branch & Region')),
        body: AppStateView.error(
          title: 'Assignment unavailable',
          message: _errorMessage ?? 'Could not load operational assignment.',
          onRetry: _load,
        ),
      );
    }

    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Branch & Region')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const PageStorageKey<String>('driver-assignment-list'),
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
                        'Operational assignment',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your approved city, service regions, branches and delivery radius.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_repository.source == DriverAssignmentDataSource.demo)
                  const StatusPill(
                    label: 'DEMO',
                    tone: StatusTone.info,
                    icon: Icons.science_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _AssignmentHero(assignment: assignment),
            const SizedBox(height: 14),
            _AssignmentCard(
              title: 'Service regions',
              icon: Icons.map_outlined,
              child: assignment.hasRegions
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final region in assignment.regions)
                          _AssignmentChip(
                            key: Key('assignment-region-$region'),
                            label: region,
                            icon: Icons.location_on_outlined,
                          ),
                      ],
                    )
                  : const Text(
                      'No service regions assigned.',
                      style: TextStyle(color: AppColors.muted),
                    ),
            ),
            const SizedBox(height: 14),
            _AssignmentCard(
              title: 'Allowed branches',
              icon: Icons.storefront_outlined,
              child: assignment.hasAllowedBranches
                  ? Column(
                      children: [
                        for (var index = 0;
                            index < assignment.allowedBranches.length;
                            index++) ...[
                          _BranchRow(branch: assignment.allowedBranches[index]),
                          if (index < assignment.allowedBranches.length - 1)
                            const Divider(height: 22, color: AppColors.border),
                        ],
                      ],
                    )
                  : const Text(
                      'No branches assigned.',
                      style: TextStyle(color: AppColors.muted),
                    ),
            ),
            const SizedBox(height: 14),
            _AssignmentCard(
              title: 'Service radius',
              icon: Icons.radar_rounded,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(.38),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.social_distance_rounded,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.serviceRadiusLabel,
                          key: const Key('assignment-service-radius'),
                          style: const TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Maximum operating radius supplied by Getin policy.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _AssignmentGovernanceCard(assignment: assignment),
            if (_repository.source == DriverAssignmentDataSource.demo) ...[
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
                        'Development assignment values are local demo data. Production city, regions, branches, radius and change permissions must come from Laravel.',
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

class _AssignmentHero extends StatelessWidget {
  final DriverAssignmentSnapshot assignment;

  const _AssignmentHero({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.location_city_outlined,
              color: AppColors.beige,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned city',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.assignedCity,
                  key: const Key('assignment-city'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            assignment.serviceRadiusLabel,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AssignmentCard({
    required this.title,
    required this.icon,
    required this.child,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AssignmentChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AssignmentChip({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  final DriverAssignedBranch branch;

  const _BranchRow({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: Key('assignment-branch-${branch.id}'),
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.beige.withOpacity(.35),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.store_outlined,
            color: AppColors.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch.name,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (branch.area != null && branch.area!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  branch.area!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignmentGovernanceCard extends StatelessWidget {
  final DriverAssignmentSnapshot assignment;

  const _AssignmentGovernanceCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final locked = !assignment.driverCanChangeAssignment;
    return Container(
      key: const Key('assignment-governance-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: locked
            ? AppColors.beige.withOpacity(.24)
            : AppColors.success.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: locked
              ? AppColors.beige.withOpacity(.72)
              : AppColors.success.withOpacity(.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            locked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            color: locked ? AppColors.green : AppColors.success,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.control.label,
                  key: const Key('assignment-control-label'),
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  assignment.policyMessage,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
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
