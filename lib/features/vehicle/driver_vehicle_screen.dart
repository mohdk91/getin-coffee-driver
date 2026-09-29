import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/widgets/getin_action_button.dart';
import '../../core/widgets/status_pill.dart';
import 'data/driver_vehicle_repository.dart';
import 'domain/driver_vehicle_models.dart';

class DriverVehicleScreen extends StatefulWidget {
  final AppConfig config;
  final DriverVehicleRepository? repository;

  const DriverVehicleScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen> {
  late final DriverVehicleRepository _repository =
      widget.repository ?? DriverVehicleRepositoryFactory.create(widget.config);

  DriverVehicleSnapshot? _vehicle;
  String? _errorMessage;
  bool _loading = true;
  bool _saving = false;

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

    final result = await _repository.loadVehicle();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _vehicle = result.vehicle;
      _errorMessage = result.errorMessage;
    });
  }

  Future<void> _editVehicle(DriverVehicleSnapshot vehicle) async {
    final request = await showModalBottomSheet<DriverVehicleUpdateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _VehicleEditSheet(vehicle: vehicle),
    );
    if (request == null || !mounted) return;

    setState(() => _saving = true);
    final result = await _repository.updateVehicle(request);
    if (!mounted) return;

    setState(() {
      _saving = false;
      if (result.vehicle != null) {
        _vehicle = result.vehicle;
      }
    });

    final message = result.isSuccess
        ? 'Vehicle details updated.'
        : result.errorMessage ?? 'Could not update vehicle details.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _vehicle == null) {
      return const Scaffold(
        body: SafeArea(
          child: AppLoadingState(label: 'Loading vehicle…'),
        ),
      );
    }

    final vehicle = _vehicle;
    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle')),
        body: SafeArea(
          child: AppStateView.error(
            title: 'Vehicle unavailable',
            message: _errorMessage ?? 'Could not load assigned vehicle.',
            onRetry: _load,
          ),
        ),
      );
    }

    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const PageStorageKey<String>('driver-vehicle-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned vehicle',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Vehicle identity, operating status and document readiness.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_repository.source == DriverVehicleDataSource.demo)
                  const StatusPill(
                    label: 'DEMO',
                    tone: StatusTone.info,
                    icon: Icons.science_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _VehicleHero(vehicle: vehicle),
            const SizedBox(height: 14),
            _VehicleDetailsCard(vehicle: vehicle),
            const SizedBox(height: 14),
            _VehicleGovernanceCard(vehicle: vehicle),
            if (vehicle.hasEditableFields) ...[
              const SizedBox(height: 14),
              GetinActionButton(
                label: _saving ? 'Saving…' : 'Edit allowed fields',
                icon: Icons.edit_outlined,
                onPressed: _saving ? null : () => _editVehicle(vehicle),
              ),
            ],
            if (_repository.source == DriverVehicleDataSource.demo) ...[
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
                        'Development vehicle data is local demo data. Laravel must supply production vehicle details and field-level edit permissions.',
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

class _VehicleHero extends StatelessWidget {
  final DriverVehicleSnapshot vehicle;

  const _VehicleHero({required this.vehicle});

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.beige.withOpacity(.55)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.two_wheeler_rounded,
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
                  vehicle.makeModel,
                  key: const Key('vehicle-make-model'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${vehicle.vehicleType} • ${vehicle.plate}',
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            label: vehicle.status.label,
            tone: _vehicleStatusTone(vehicle.status),
          ),
        ],
      ),
    );
  }
}

class _VehicleDetailsCard extends StatelessWidget {
  final DriverVehicleSnapshot vehicle;

  const _VehicleDetailsCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _VehicleCard(
      title: 'Vehicle details',
      icon: Icons.directions_car_outlined,
      children: [
        _VehicleRow(
          label: 'Vehicle type',
          value: vehicle.vehicleType,
          icon: Icons.category_outlined,
          editable: vehicle.canEdit(DriverVehicleField.vehicleType),
          valueKey: const Key('vehicle-type-value'),
        ),
        const _VehicleDivider(),
        _VehicleRow(
          label: 'Plate',
          value: vehicle.plate,
          icon: Icons.confirmation_number_outlined,
          editable: vehicle.canEdit(DriverVehicleField.plate),
          valueKey: const Key('vehicle-plate-value'),
        ),
        const _VehicleDivider(),
        _VehicleRow(
          label: 'Make / model',
          value: vehicle.makeModel,
          icon: Icons.two_wheeler_rounded,
          editable: vehicle.canEdit(DriverVehicleField.makeModel),
        ),
        const _VehicleDivider(),
        _VehicleRow(
          label: 'Color',
          value: vehicle.color,
          icon: Icons.palette_outlined,
          editable: vehicle.canEdit(DriverVehicleField.color),
          valueKey: const Key('vehicle-color-value'),
        ),
      ],
    );
  }
}

class _VehicleGovernanceCard extends StatelessWidget {
  final DriverVehicleSnapshot vehicle;

  const _VehicleGovernanceCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _VehicleCard(
      title: 'Getin status',
      icon: Icons.verified_user_outlined,
      children: [
        _StatusRow(
          label: 'Vehicle status',
          icon: Icons.power_settings_new_rounded,
          statusLabel: vehicle.status.label,
          tone: _vehicleStatusTone(vehicle.status),
          valueKey: const Key('vehicle-status-value'),
        ),
        const _VehicleDivider(),
        _StatusRow(
          label: 'Document status',
          icon: Icons.description_outlined,
          statusLabel: vehicle.documentStatus.label,
          tone: _documentStatusTone(vehicle.documentStatus),
          valueKey: const Key('vehicle-document-status-value'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Status and document approval are controlled by Getin operations. The Driver App cannot override them.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _VehicleCard({
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

class _VehicleRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool editable;
  final Key? valueKey;

  const _VehicleRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.editable,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RowIcon(icon: icon),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    editable ? Icons.edit_outlined : Icons.lock_outline_rounded,
                    color: editable ? AppColors.success : AppColors.muted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    editable ? 'Editable' : 'Managed',
                    style: TextStyle(
                      color: editable ? AppColors.success : AppColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
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

class _StatusRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String statusLabel;
  final StatusTone tone;
  final Key? valueKey;

  const _StatusRow({
    required this.label,
    required this.icon,
    required this.statusLabel,
    required this.tone,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RowIcon(icon: icon),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.greenDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        KeyedSubtree(
          key: valueKey,
          child: StatusPill(label: statusLabel, tone: tone),
        ),
      ],
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;

  const _RowIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.green, size: 18),
    );
  }
}

class _VehicleDivider extends StatelessWidget {
  const _VehicleDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _VehicleEditSheet extends StatefulWidget {
  final DriverVehicleSnapshot vehicle;

  const _VehicleEditSheet({required this.vehicle});

  @override
  State<_VehicleEditSheet> createState() => _VehicleEditSheetState();
}

class _VehicleEditSheetState extends State<_VehicleEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vehicleTypeController;
  late final TextEditingController _plateController;
  late final TextEditingController _makeModelController;
  late final TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    _vehicleTypeController =
        TextEditingController(text: widget.vehicle.vehicleType);
    _plateController = TextEditingController(text: widget.vehicle.plate);
    _makeModelController =
        TextEditingController(text: widget.vehicle.makeModel);
    _colorController = TextEditingController(text: widget.vehicle.color);
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _plateController.dispose();
    _makeModelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit vehicle',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                'Only fields currently permitted by Getin can be changed.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _EditField(
                key: const Key('vehicle-edit-type'),
                label: 'Vehicle type',
                controller: _vehicleTypeController,
                enabled: widget.vehicle.canEdit(DriverVehicleField.vehicleType),
              ),
              const SizedBox(height: 12),
              _EditField(
                key: const Key('vehicle-edit-plate'),
                label: 'Plate',
                controller: _plateController,
                enabled: widget.vehicle.canEdit(DriverVehicleField.plate),
              ),
              const SizedBox(height: 12),
              _EditField(
                key: const Key('vehicle-edit-make-model'),
                label: 'Make / model',
                controller: _makeModelController,
                enabled: widget.vehicle.canEdit(DriverVehicleField.makeModel),
              ),
              const SizedBox(height: 12),
              _EditField(
                key: const Key('vehicle-edit-color'),
                label: 'Color',
                controller: _colorController,
                enabled: widget.vehicle.canEdit(DriverVehicleField.color),
              ),
              const SizedBox(height: 18),
              GetinActionButton(
                label: 'Save allowed changes',
                icon: Icons.save_outlined,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      DriverVehicleUpdateRequest(
        vehicleType: _vehicleTypeController.text,
        plate: _plateController.text,
        makeModel: _makeModelController.text,
        color: _colorController.text,
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _EditField({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(
          enabled ? Icons.edit_outlined : Icons.lock_outline_rounded,
          size: 18,
        ),
      ),
      validator: (value) {
        if (!enabled) return null;
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }
        return null;
      },
    );
  }
}

StatusTone _vehicleStatusTone(DriverVehicleStatus status) {
  return switch (status) {
    DriverVehicleStatus.active => StatusTone.success,
    DriverVehicleStatus.inactive => StatusTone.neutral,
    DriverVehicleStatus.pendingApproval => StatusTone.warning,
    DriverVehicleStatus.suspended => StatusTone.danger,
  };
}

StatusTone _documentStatusTone(DriverVehicleDocumentStatus status) {
  return switch (status) {
    DriverVehicleDocumentStatus.valid => StatusTone.success,
    DriverVehicleDocumentStatus.expiringSoon => StatusTone.warning,
    DriverVehicleDocumentStatus.pendingReview => StatusTone.info,
    DriverVehicleDocumentStatus.expired => StatusTone.danger,
    DriverVehicleDocumentStatus.rejected => StatusTone.danger,
  };
}
