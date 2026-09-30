import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../system/app_runtime_info.dart';
import '../system/mobile_system_config.dart';
import '../system/mobile_system_config_repository.dart';
import '../theme/app_colors.dart';

enum MobileAppKind { customer, driver }

class MobileSystemConfigScope extends InheritedWidget {
  final MobileSystemConfig config;

  const MobileSystemConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  static MobileSystemConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MobileSystemConfigScope>()
        ?.config;
  }

  @override
  bool updateShouldNotify(MobileSystemConfigScope oldWidget) {
    return oldWidget.config != config;
  }
}

class MobileStartupGate extends StatefulWidget {
  final AppConfig appConfig;
  final MobileAppKind appKind;
  final Widget child;
  final MobileSystemConfigLoader? loader;
  final AppRuntimeInfoProvider runtimeInfoProvider;

  const MobileStartupGate({
    super.key,
    required this.appConfig,
    required this.appKind,
    required this.child,
    this.loader,
    this.runtimeInfoProvider = const PackageAppRuntimeInfoProvider(),
  });

  @override
  State<MobileStartupGate> createState() => _MobileStartupGateState();
}

class _MobileStartupGateState extends State<MobileStartupGate> {
  MobileSystemConfig? _systemConfig;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.appConfig.isApiConfigured) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.appConfig.requiresApi
            ? StateError('API_BASE_URL is required outside development.')
            : null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final runtime = await widget.runtimeInfoProvider.load();
      final loader = widget.loader;
      if (loader == null) {
        throw StateError('Mobile system config loader is not configured.');
      }
      final config = await loader.fetch(
        platform: runtime.platform,
        version: runtime.version,
      );

      if (!mounted) return;
      setState(() {
        _systemConfig = config;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _StartupShell(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _StartupShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 46),
            const SizedBox(height: 16),
            const Text(
              'Unable to connect to GETIN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final config = _systemConfig;
    if (config == null) {
      return widget.child;
    }

    final appEnabled = widget.appKind == MobileAppKind.customer
        ? config.customerFeatures.enabled('app')
        : config.driverFeatures.enabled('app');

    if (!appEnabled) {
      return const _StartupShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline, size: 48),
            SizedBox(height: 16),
            Text(
              'This GETIN app is currently unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'The service has been temporarily disabled by GETIN operations.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (config.maintenance.enabled) {
      return _StartupShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'GETIN is temporarily unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              (config.maintenance.message == null ||
                      config.maintenance.message!.trim().isEmpty)
                  ? 'We are performing scheduled maintenance. Please try again shortly.'
                  : config.maintenance.message!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: _load, child: const Text('Check again')),
          ],
        ),
      );
    }

    if (config.client.updateRequired == true) {
      return _StartupShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.system_update_alt, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Update required',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Please update GETIN to version ${config.client.latestVersion ?? 'the latest version'} to continue.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return MobileSystemConfigScope(config: config, child: widget.child);
  }
}

class _StartupShell extends StatelessWidget {
  final Widget child;

  const _StartupShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.green),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
