import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/status_pill.dart';
import '../background_location/data/driver_background_location_controller.dart';
import '../background_location/domain/driver_background_location_models.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_gps_gateway.dart';
import 'data/driver_location_repository.dart';
import 'domain/driver_location_models.dart';

class DriverLocationServiceRegionScreen extends StatefulWidget {
  final AppConfig config;
  final DriverLocationRepository repository;
  final DriverGpsGateway? gpsGateway;
  final DriverBackgroundLocationController? backgroundLocationController;
  final ValueChanged<DriverGpsState>? onGpsStateChanged;

  const DriverLocationServiceRegionScreen({
    super.key,
    required this.config,
    required this.repository,
    this.gpsGateway,
    this.backgroundLocationController,
    this.onGpsStateChanged,
  });

  @override
  State<DriverLocationServiceRegionScreen> createState() =>
      _DriverLocationServiceRegionScreenState();
}

class _DriverLocationServiceRegionScreenState
    extends State<DriverLocationServiceRegionScreen> {
  late final DriverGpsGateway _gpsGateway =
      widget.gpsGateway ?? const DeviceDriverGpsGateway();

  DriverServiceRegionProfile? _profile;
  DriverGpsHealthSnapshot? _gpsHealth;
  String? _errorMessage;
  bool _loading = true;
  bool _gpsBusy = false;

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

    final profileResult = await widget.repository.loadLocationProfile();
    final gpsHealth = await _gpsGateway.check();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _gpsHealth = gpsHealth;
      if (profileResult.isSuccess) {
        _profile = profileResult.profile;
      } else {
        _profile = null;
        _errorMessage = profileResult.errorMessage;
      }
    });
    widget.onGpsStateChanged?.call(gpsHealth.homeState);
  }

  Future<void> _retryGps({bool requestPermission = false}) async {
    if (_gpsBusy) return;
    setState(() => _gpsBusy = true);

    final health = await _gpsGateway.check(
      requestPermission: requestPermission,
    );
    if (!mounted) return;

    setState(() {
      _gpsHealth = health;
      _gpsBusy = false;
    });
    widget.onGpsStateChanged?.call(health.homeState);
  }

  Future<void> _resolveGpsIssue(DriverGpsHealthSnapshot health) async {
    switch (health.issue) {
      case DriverGpsHandlingIssue.locationDisabled:
        await _gpsGateway.openLocationSettings();
        await _retryGps();
        return;
      case DriverGpsHandlingIssue.permissionDenied:
        if (health.foregroundPermission ==
            DriverLocationPermissionState.deniedForever) {
          await _gpsGateway.openAppSettings();
          await _retryGps();
        } else {
          await _retryGps(requestPermission: true);
        }
        return;
      case DriverGpsHandlingIssue.backgroundPermissionDenied:
        await _gpsGateway.openAppSettings();
        await _retryGps();
        return;
      case DriverGpsHandlingIssue.staleLocation:
      case DriverGpsHandlingIssue.inaccurateGps:
      case DriverGpsHandlingIssue.unavailable:
      case DriverGpsHandlingIssue.ready:
        await _retryGps();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('GPS & Service Region')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _profile == null) {
      return const AppLoadingState(label: 'Loading driver location…');
    }

    final profile = _profile;
    if (profile == null) {
      return AppStateView.error(
        title: 'Location profile unavailable',
        message: _errorMessage ?? 'Could not load driver location details.',
        onRetry: _load,
      );
    }

    final padding = Responsive.horizontalPadding(context);
    final health = _gpsHealth;

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
            children: [
              if (widget.repository.source ==
                  DriverLocationDataSource.demo) ...[
                _DemoLocationBanner(gpsSource: _gpsGateway.source),
                const SizedBox(height: 16),
              ],
              if (health != null) ...[
                _GpsHandlingCard(
                  health: health,
                  busy: _gpsBusy,
                  onResolve: () => _resolveGpsIssue(health),
                ),
                const SizedBox(height: 16),
                _GpsDiagnosticsCard(health: health),
                const SizedBox(height: 16),
                _GpsCard(health: health),
                const SizedBox(height: 16),
              ],
              if (widget.backgroundLocationController != null) ...[
                _BackgroundOperationCard(
                  controller: widget.backgroundLocationController!,
                ),
                const SizedBox(height: 16),
              ],
              if (_gpsGateway is DemoDriverGpsGateway) ...[
                _GpsScenarioCard(
                  gateway: _gpsGateway,
                  onChanged: () => _retryGps(),
                ),
                const SizedBox(height: 16),
              ],
              _AssignmentCard(profile: profile),
              const SizedBox(height: 16),
              const _BackendPolicyCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_loading || _gpsBusy) ? null : _load,
                  icon: (_loading || _gpsBusy)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Retry GPS & refresh assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoLocationBanner extends StatelessWidget {
  final DriverGpsGatewaySource gpsSource;

  const _DemoLocationBanner({required this.gpsSource});

  @override
  Widget build(BuildContext context) {
    final gpsText = switch (gpsSource) {
      DriverGpsGatewaySource.device =>
        'GPS health is read from this device; service assignment remains development sample data.',
      DriverGpsGatewaySource.demo =>
        'GPS health and service assignment are development sample data.',
      DriverGpsGatewaySource.unavailable =>
        'Service assignment is development sample data; GPS is unavailable.',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(.34),
        border: Border.all(color: AppColors.beige),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.science_outlined,
            color: AppColors.greenDark,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Development mode. $gpsText',
              style: const TextStyle(
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

class _GpsHandlingCard extends StatelessWidget {
  final DriverGpsHealthSnapshot health;
  final bool busy;
  final VoidCallback onResolve;

  const _GpsHandlingCard({
    required this.health,
    required this.busy,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = _GpsIssuePresentation.from(health);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: const BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(presentation.icon, color: AppColors.beige, size: 25),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GPS handling',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      presentation.label,
                      style: const TextStyle(
                        color: AppColors.beige,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: presentation.shortLabel,
                tone: presentation.tone,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            health.message,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onResolve,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.beige),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(presentation.actionIcon),
              label: Text(presentation.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsDiagnosticsCard extends StatelessWidget {
  final DriverGpsHealthSnapshot health;

  const _GpsDiagnosticsCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final fix = health.fix;
    final age = fix == null
        ? 'No fix'
        : _formatAge(
            Duration(
              milliseconds: health.checkedAt
                  .difference(fix.capturedAt)
                  .inMilliseconds
                  .abs(),
            ),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPS diagnostics',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Task #37 checks the conditions that can block reliable delivery tracking.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _DiagnosticRow(
              label: 'Location services',
              value: health.locationServicesEnabled ? 'Enabled' : 'Disabled',
              healthy: health.locationServicesEnabled,
            ),
            const Divider(height: 22),
            _DiagnosticRow(
              label: 'Foreground permission',
              value: _foregroundLabel(health.foregroundPermission),
              healthy: health.foregroundPermission ==
                  DriverLocationPermissionState.granted,
            ),
            const Divider(height: 22),
            _DiagnosticRow(
              label: 'Background permission',
              value: _backgroundLabel(health.backgroundPermission),
              healthy: health.backgroundPermission ==
                  DriverBackgroundPermissionState.granted,
            ),
            const Divider(height: 22),
            _DiagnosticRow(
              label: 'Location freshness',
              value: age,
              healthy: health.issue != DriverGpsHandlingIssue.staleLocation &&
                  fix != null,
            ),
            const Divider(height: 22),
            _DiagnosticRow(
              label: 'GPS accuracy',
              value: fix == null
                  ? 'No fix'
                  : '±${fix.accuracyMeters.toStringAsFixed(0)} m',
              healthy: health.issue != DriverGpsHandlingIssue.inaccurateGps &&
                  fix != null,
            ),
          ],
        ),
      ),
    );
  }

  static String _foregroundLabel(DriverLocationPermissionState state) {
    return switch (state) {
      DriverLocationPermissionState.granted => 'Granted',
      DriverLocationPermissionState.denied => 'Denied',
      DriverLocationPermissionState.deniedForever => 'Blocked in settings',
      DriverLocationPermissionState.unknown => 'Unknown',
    };
  }

  static String _backgroundLabel(DriverBackgroundPermissionState state) {
    return switch (state) {
      DriverBackgroundPermissionState.granted => 'Granted',
      DriverBackgroundPermissionState.denied => 'Denied',
      DriverBackgroundPermissionState.unknown => 'Unknown',
    };
  }

  static String _formatAge(Duration age) {
    if (age.inSeconds < 60) return '${age.inSeconds}s old';
    if (age.inMinutes < 60) return '${age.inMinutes}m old';
    return '${age.inHours}h old';
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final bool healthy;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.healthy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          healthy ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: healthy ? AppColors.green : AppColors.muted,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GpsCard extends StatelessWidget {
  final DriverGpsHealthSnapshot health;

  const _GpsCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final gps = health.fix;
    final presentation = _GpsIssuePresentation.from(health);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: AppColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current GPS',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Device fix used to assess delivery readiness.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: presentation.shortLabel,
                  tone: presentation.tone,
                ),
              ],
            ),
            const SizedBox(height: 17),
            if (gps == null)
              const Text(
                'No current GPS fix is available. Resolve the issue above and retry.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              _DetailRow(
                icon: Icons.my_location_rounded,
                label: 'Coordinates',
                value:
                    '${gps.coordinates.latitude.toStringAsFixed(5)}, ${gps.coordinates.longitude.toStringAsFixed(5)}',
              ),
              const Divider(height: 22),
              _DetailRow(
                icon: Icons.center_focus_strong_rounded,
                label: 'GPS accuracy',
                value: '±${gps.accuracyMeters.toStringAsFixed(0)} m',
              ),
              const Divider(height: 22),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Last location update',
                value: _formatDateTime(gps.capturedAt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} • $hour:$minute';
  }
}

class _BackgroundOperationCard extends StatelessWidget {
  final DriverBackgroundLocationController controller;

  const _BackgroundOperationCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.snapshot;
        final settings = snapshot.settings;
        final fix = snapshot.lastFix;
        final tone = switch (snapshot.status) {
          DriverBackgroundTrackingStatus.tracking => StatusTone.success,
          DriverBackgroundTrackingStatus.starting => StatusTone.info,
          DriverBackgroundTrackingStatus.blocked => StatusTone.warning,
          DriverBackgroundTrackingStatus.error => StatusTone.danger,
          DriverBackgroundTrackingStatus.stopped => StatusTone.neutral,
        };

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.location_history_rounded,
                        color: AppColors.green,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background operation',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Task #39 battery-aware location tracking.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: snapshot.status.label,
                      tone: tone,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  snapshot.message,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                _DetailRow(
                  icon: Icons.policy_outlined,
                  label: 'Policy',
                  value: snapshot.policy?.version ?? 'Waiting for backend',
                ),
                const Divider(height: 22),
                _DetailRow(
                  icon: Icons.memory_rounded,
                  label: 'Location runner',
                  value: controller.isDeviceRunner ? 'Device GPS' : 'Demo GPS',
                ),
                const Divider(height: 22),
                _DetailRow(
                  icon: Icons.sync_rounded,
                  label: 'Server location sync',
                  value: snapshot.serverSyncAllowed ? 'Allowed' : 'Paused',
                ),
                if (settings != null) ...[
                  const Divider(height: 22),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Update profile',
                    value:
                        '${settings.interval.inSeconds}s • ${settings.distanceFilterMeters} m',
                  ),
                ],
                if (fix != null) ...[
                  const Divider(height: 22),
                  _DetailRow(
                    icon: Icons.my_location_rounded,
                    label: 'Last background fix',
                    value:
                        '${fix.coordinates.latitude.toStringAsFixed(5)}, ${fix.coordinates.longitude.toStringAsFixed(5)}',
                  ),
                ],
                if (controller.isDemoPolicy) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(.28),
                      border: Border.all(color: AppColors.beige),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      controller.isDeviceRunner
                          ? 'Development policy • REAL device background GPS enabled by dart-define.'
                          : 'Development policy • Demo background GPS. Use DRIVER_REAL_BACKGROUND_GPS=true on a physical device to exercise the native stream.',
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GpsScenarioCard extends StatelessWidget {
  final DemoDriverGpsGateway gateway;
  final VoidCallback onChanged;

  const _GpsScenarioCard({
    required this.gateway,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const scenarios = <DriverGpsHandlingIssue, String>{
      DriverGpsHandlingIssue.ready: 'Ready',
      DriverGpsHandlingIssue.locationDisabled: 'Location disabled',
      DriverGpsHandlingIssue.permissionDenied: 'Permission denied',
      DriverGpsHandlingIssue.backgroundPermissionDenied: 'Background denied',
      DriverGpsHandlingIssue.staleLocation: 'Stale',
      DriverGpsHandlingIssue.inaccurateGps: 'Inaccurate',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demo GPS scenarios',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Test every Task #37 state without changing device settings.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scenarios.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: gateway.scenario == entry.key,
                  onSelected: (_) {
                    gateway.setScenario(entry.key);
                    onChanged();
                  },
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final DriverServiceRegionProfile profile;

  const _AssignmentCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service assignment',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Operational coverage assigned to this driver profile.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 17),
            _DetailRow(
              icon: Icons.public_rounded,
              label: 'Country',
              value: profile.country,
            ),
            const Divider(height: 22),
            _DetailRow(
              icon: Icons.location_city_rounded,
              label: 'City',
              value: profile.city,
            ),
            const Divider(height: 22),
            _DetailRow(
              icon: Icons.map_outlined,
              label: 'Region / zone',
              value: '${profile.region} • ${profile.zone}',
            ),
            const Divider(height: 22),
            _DetailRow(
              icon: Icons.radar_rounded,
              label: 'Delivery radius',
              value: '${profile.deliveryRadiusKm.toStringAsFixed(0)} km',
            ),
            const Divider(height: 22),
            _DetailRow(
              icon: Icons.two_wheeler_rounded,
              label: 'Vehicle type',
              value: profile.vehicleType,
            ),
            const Divider(height: 22),
            const Text(
              'Allowed branches',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.allowedBranches
                  .map(
                    (branch) => StatusPill(
                      label: branch,
                      tone: StatusTone.info,
                      icon: Icons.storefront_rounded,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackendPolicyCard extends StatelessWidget {
  const _BackendPolicyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.policy_outlined, color: AppColors.beige, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operational GPS policy',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'The app now detects device location services, foreground/background permission, stale fixes and inaccurate GPS. Assignment data remains controlled by Getin operations.',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'A non-ready GPS state can be surfaced to eligibility and delivery flows instead of silently accepting unreliable location data.',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.green, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 12.5,
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

class _GpsIssuePresentation {
  final String label;
  final String shortLabel;
  final String actionLabel;
  final IconData icon;
  final IconData actionIcon;
  final StatusTone tone;

  const _GpsIssuePresentation({
    required this.label,
    required this.shortLabel,
    required this.actionLabel,
    required this.icon,
    required this.actionIcon,
    required this.tone,
  });

  factory _GpsIssuePresentation.from(DriverGpsHealthSnapshot health) {
    return switch (health.issue) {
      DriverGpsHandlingIssue.ready => const _GpsIssuePresentation(
          label: 'Location ready',
          shortLabel: 'Ready',
          actionLabel: 'Refresh GPS',
          icon: Icons.gps_fixed_rounded,
          actionIcon: Icons.refresh_rounded,
          tone: StatusTone.success,
        ),
      DriverGpsHandlingIssue.locationDisabled => const _GpsIssuePresentation(
          label: 'Location services disabled',
          shortLabel: 'Disabled',
          actionLabel: 'Open location settings',
          icon: Icons.location_off_rounded,
          actionIcon: Icons.settings_rounded,
          tone: StatusTone.danger,
        ),
      DriverGpsHandlingIssue.permissionDenied => _GpsIssuePresentation(
          label: 'Location permission denied',
          shortLabel: 'Permission',
          actionLabel: health.foregroundPermission ==
                  DriverLocationPermissionState.deniedForever
              ? 'Open app settings'
              : 'Grant location permission',
          icon: Icons.gpp_bad_outlined,
          actionIcon: Icons.admin_panel_settings_outlined,
          tone: StatusTone.danger,
        ),
      DriverGpsHandlingIssue.backgroundPermissionDenied =>
        const _GpsIssuePresentation(
          label: 'Background location denied',
          shortLabel: 'Background',
          actionLabel: 'Open app settings',
          icon: Icons.layers_clear_outlined,
          actionIcon: Icons.settings_applications_outlined,
          tone: StatusTone.warning,
        ),
      DriverGpsHandlingIssue.staleLocation => const _GpsIssuePresentation(
          label: 'Location fix is stale',
          shortLabel: 'Stale',
          actionLabel: 'Retry GPS',
          icon: Icons.history_rounded,
          actionIcon: Icons.refresh_rounded,
          tone: StatusTone.warning,
        ),
      DriverGpsHandlingIssue.inaccurateGps => const _GpsIssuePresentation(
          label: 'GPS accuracy is too low',
          shortLabel: 'Inaccurate',
          actionLabel: 'Retry GPS',
          icon: Icons.gps_not_fixed_rounded,
          actionIcon: Icons.refresh_rounded,
          tone: StatusTone.warning,
        ),
      DriverGpsHandlingIssue.unavailable => const _GpsIssuePresentation(
          label: 'GPS fix unavailable',
          shortLabel: 'Unavailable',
          actionLabel: 'Retry GPS',
          icon: Icons.location_searching_rounded,
          actionIcon: Icons.refresh_rounded,
          tone: StatusTone.danger,
        ),
    };
  }
}
