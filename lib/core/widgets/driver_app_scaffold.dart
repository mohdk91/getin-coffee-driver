import 'package:flutter/material.dart';

import '../navigation/driver_tab.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import 'connectivity_banner.dart';
import 'active_delivery_bar.dart';

class DriverAppScaffold extends StatelessWidget {
  final DriverTab currentTab;
  final ValueChanged<DriverTab> onTabChanged;
  final Widget body;
  final VoidCallback? onNotifications;
  final VoidCallback? onSupport;
  final bool hasUnreadNotifications;
  final String? activeOrderNumber;
  final String? activeDeliveryStatus;
  final VoidCallback? onActiveDelivery;
  final bool offline;
  final DateTime? lastSuccessfulSyncAt;
  final bool retryingConnection;
  final VoidCallback? onRetryConnection;

  const DriverAppScaffold({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.body,
    this.onNotifications,
    this.onSupport,
    this.hasUnreadNotifications = false,
    this.activeOrderNumber,
    this.activeDeliveryStatus,
    this.onActiveDelivery,
    this.offline = false,
    this.lastSuccessfulSyncAt,
    this.retryingConnection = false,
    this.onRetryConnection,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = [
      for (final tab in DriverTab.values)
        NavigationDestination(icon: Icon(tab.icon), label: tab.label),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        titleSpacing: Responsive.horizontalPadding(context),
        title: const Text(
          'Getin Driver',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Getin Support',
            onPressed: onSupport,
            icon: const Icon(Icons.support_agent_rounded),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (hasUnreadNotifications)
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          if (offline)
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                10,
                Responsive.horizontalPadding(context),
                0,
              ),
              child: ConnectivityBanner(
                tone: WarningBannerTone.offline,
                title: retryingConnection
                    ? 'Checking connection…'
                    : "You're offline",
                message:
                    'Cached read-only information can remain visible. ${_lastSyncLabel(lastSuccessfulSyncAt)} Critical actions stay locked until Getin reconnects.',
                onRetry: retryingConnection ? null : onRetryConnection,
              ),
            ),
          if (activeOrderNumber != null && onActiveDelivery != null)
            ActiveDeliveryBar(
              orderNumber: activeOrderNumber!,
              status: activeDeliveryStatus ?? 'Delivery in progress',
              onTap: onActiveDelivery!,
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) => onTabChanged(DriverTab.values[index]),
        destinations: destinations,
      ),
    );
  }

  static String _lastSyncLabel(DateTime? value) {
    if (value == null) return 'No successful sync yet.';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Last sync ${local.day}/${local.month} at $hour:$minute.';
  }
}
