import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_action_button.dart';
import 'data/driver_navigation_launcher.dart';
import 'data/driver_navigation_preference_store.dart';
import 'domain/driver_navigation_models.dart';

class DriverNavigationCard extends StatefulWidget {
  final DriverNavigationTarget target;
  final DriverNavigationLauncher? launcher;
  final DriverNavigationPreferenceStore? preferenceStore;

  const DriverNavigationCard({
    super.key,
    required this.target,
    this.launcher,
    this.preferenceStore,
  });

  @override
  State<DriverNavigationCard> createState() => _DriverNavigationCardState();
}

class _DriverNavigationCardState extends State<DriverNavigationCard> {
  late final DriverNavigationLauncher _launcher =
      widget.launcher ?? const UrlLauncherDriverNavigationLauncher();
  late final DriverNavigationPreferenceStore _preferenceStore =
      widget.preferenceStore ??
          const SharedPreferencesDriverNavigationPreferenceStore();

  DriverNavigationApp _preferred = DriverNavigationApp.systemDefault;
  bool _loadingPreference = true;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preferred = await _preferenceStore.loadPreferredApp();
    if (!mounted) return;
    setState(() {
      _preferred = preferred;
      _loadingPreference = false;
    });
  }

  Future<void> _launch(DriverNavigationApp app) async {
    if (_launching) return;
    setState(() => _launching = true);

    final result = await _launcher.launch(app: app, target: widget.target);
    if (!mounted) return;

    setState(() => _launching = false);
    if (!result.launched) {
      _showMessage(
        result.errorMessage ?? 'Navigation could not be opened.',
      );
    }
  }

  Future<void> _chooseApp() async {
    final selected = await showModalBottomSheet<DriverNavigationApp>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (context) {
        final appleAvailable =
            _launcher.platform == DriverNavigationPlatform.ios;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose navigation app',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your choice becomes the preferred app for the next navigation action.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _NavigationChoiceTile(
                  icon: Icons.navigation_rounded,
                  title: 'System default',
                  subtitle: 'Use the navigation app selected by this device.',
                  selected: _preferred == DriverNavigationApp.systemDefault,
                  onTap: () => Navigator.pop(
                    context,
                    DriverNavigationApp.systemDefault,
                  ),
                ),
                _NavigationChoiceTile(
                  icon: Icons.map_rounded,
                  title: 'Google Maps',
                  subtitle: 'Open Google Maps with driving directions.',
                  selected: _preferred == DriverNavigationApp.googleMaps,
                  onTap: () => Navigator.pop(
                    context,
                    DriverNavigationApp.googleMaps,
                  ),
                ),
                _NavigationChoiceTile(
                  icon: Icons.map_outlined,
                  title: 'Apple Maps',
                  subtitle: appleAvailable
                      ? 'Open Apple Maps with driving directions.'
                      : 'Available on iPhone and iPad.',
                  selected: _preferred == DriverNavigationApp.appleMaps,
                  onTap: appleAvailable
                      ? () => Navigator.pop(
                            context,
                            DriverNavigationApp.appleMaps,
                          )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    await _preferenceStore.savePreferredApp(selected);
    if (!mounted) return;
    setState(() => _preferred = selected);
    await _launch(selected);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferredLabel =
        _loadingPreference ? 'Loading preference…' : _preferred.shortLabel;

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
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.beige.withOpacity(.35),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navigation',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Open turn-by-turn directions in an external maps app.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.8,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Preferred',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    preferredLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GetinActionButton(
            label: _launching ? 'Opening Navigation…' : 'Open Navigation',
            icon: Icons.directions_rounded,
            onPressed: _loadingPreference || _launching
                ? null
                : () => _launch(_preferred),
          ),
          const SizedBox(height: 8),
          GetinActionButton(
            label: 'Choose Navigation App',
            icon: Icons.apps_rounded,
            secondary: true,
            onPressed: _launching ? null : _chooseApp,
          ),
        ],
      ),
    );
  }
}

class _NavigationChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _NavigationChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: CircleAvatar(
        backgroundColor:
            onTap == null ? AppColors.border : AppColors.beige.withOpacity(.45),
        foregroundColor: onTap == null ? AppColors.muted : AppColors.green,
        child: Icon(icon, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.greenDark,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
