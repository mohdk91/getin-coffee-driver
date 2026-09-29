import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_state_view.dart';
import 'data/driver_notifications_repository.dart';
import 'domain/driver_notification_models.dart';

enum _NotificationFilter { all, unread }

class DriverNotificationsScreen extends StatefulWidget {
  final AppConfig config;
  final DriverNotificationsRepository? repository;
  final ValueChanged<int>? onUnreadCountChanged;

  const DriverNotificationsScreen({
    super.key,
    required this.config,
    this.repository,
    this.onUnreadCountChanged,
  });

  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  late final DriverNotificationsRepository _repository = widget.repository ??
      DriverNotificationsRepositoryFactory.create(widget.config);

  DriverNotificationsSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  bool _changingReadState = false;
  _NotificationFilter _filter = _NotificationFilter.all;

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

    final result = await _repository.loadNotifications();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _snapshot = result.snapshot;
      _errorMessage = result.errorMessage;
    });

    final snapshot = result.snapshot;
    if (snapshot != null) {
      widget.onUnreadCountChanged?.call(snapshot.unreadCount);
    }
  }

  Future<void> _markRead(DriverNotificationItem item) async {
    if (item.isRead || _changingReadState) return;

    setState(() => _changingReadState = true);
    final result = await _repository.markRead(item.id);
    if (!mounted) return;

    setState(() {
      _changingReadState = false;
      if (result.isSuccess) {
        _snapshot = result.snapshot;
      }
    });

    if (result.isSuccess) {
      widget.onUnreadCountChanged?.call(result.snapshot!.unreadCount);
    } else {
      _showMessage(result.errorMessage ?? 'Could not update notification.');
    }
  }

  Future<void> _markAllRead() async {
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.unreadCount == 0 || _changingReadState) {
      return;
    }

    setState(() => _changingReadState = true);
    final result = await _repository.markAllRead();
    if (!mounted) return;

    setState(() {
      _changingReadState = false;
      if (result.isSuccess) {
        _snapshot = result.snapshot;
      }
    });

    if (result.isSuccess) {
      widget.onUnreadCountChanged?.call(result.snapshot!.unreadCount);
      _showMessage('All notifications marked as read.');
    } else {
      _showMessage(result.errorMessage ?? 'Could not update notifications.');
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const Scaffold(
        body: SafeArea(
          child: AppLoadingState(label: 'Loading notifications…'),
        ),
      );
    }

    if (_snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: SafeArea(
          child: AppStateView.error(
            title: 'Notifications unavailable',
            message: _errorMessage ?? 'Could not load driver notifications.',
            onRetry: _load,
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final visibleItems = _filter == _NotificationFilter.unread
        ? snapshot.items.where((item) => !item.isRead).toList()
        : snapshot.items;
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: snapshot.unreadCount == 0 || _changingReadState
                ? null
                : _markAllRead,
            child: const Text('Mark all read'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver alerts',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.unreadCount == 0
                            ? 'You are all caught up.'
                            : '${snapshot.unreadCount} unread notifications',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _UnreadBadge(count: snapshot.unreadCount),
              ],
            ),
            if (_repository.source == DriverNotificationDataSource.demo) ...[
              const SizedBox(height: 10),
              const Text(
                'DEMO NOTIFICATIONS • Not connected to Laravel or push delivery',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _NotificationFilterSelector(
              selected: _filter,
              unreadCount: snapshot.unreadCount,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 18),
            const Text(
              'Notification categories',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const _CategoryOverview(),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _filter == _NotificationFilter.unread
                        ? 'Unread notifications'
                        : 'Recent notifications',
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${visibleItems.length} alerts',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (visibleItems.isEmpty)
              const _NoNotificationsCard()
            else
              ...visibleItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationCard(
                    item: item,
                    disabled: _changingReadState,
                    onTap: () => _markRead(item),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            const _NotificationPolicyCard(),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 46),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: count == 0 ? AppColors.cream : AppColors.greenDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: count == 0 ? AppColors.border : AppColors.greenDark,
        ),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: count == 0 ? AppColors.muted : AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationFilterSelector extends StatelessWidget {
  final _NotificationFilter selected;
  final int unreadCount;
  final ValueChanged<_NotificationFilter> onSelected;

  const _NotificationFilterSelector({
    required this.selected,
    required this.unreadCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _FilterOption(
            label: 'All',
            active: selected == _NotificationFilter.all,
            onTap: () => onSelected(_NotificationFilter.all),
          ),
          _FilterOption(
            label: 'Unread ($unreadCount)',
            active: selected == _NotificationFilter.unread,
            onTap: () => onSelected(_NotificationFilter.unread),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.white : AppColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryOverview extends StatelessWidget {
  const _CategoryOverview();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: DriverNotificationCategory.values
          .map(
            (category) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                category.label,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final DriverNotificationItem item;
  final bool disabled;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(item.category);

    return Material(
      color: item.isRead ? AppColors.white : AppColors.cream,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.isRead || disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: item.isRead ? AppColors.border : AppColors.beige,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: presentation.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.foreground,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.category.label,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.orderNumber != null)
                          Text(
                            item.orderNumber!,
                            style: const TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        Text(
                          _relativeTime(item.createdAt),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item.isRead ? 'Read' : 'Tap to mark read',
                          style: TextStyle(
                            color:
                                item.isRead ? AppColors.muted : AppColors.info,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoNotificationsCard extends StatelessWidget {
  const _NoNotificationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none_rounded, color: AppColors.muted),
          SizedBox(height: 8),
          Text(
            'No unread notifications',
            style: TextStyle(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPolicyCard extends StatelessWidget {
  const _NotificationPolicyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notification content, read state and future push/deep-link actions must come from Laravel. The demo only proves the Driver App notification experience.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPresentation {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _CategoryPresentation({
    required this.icon,
    required this.foreground,
    required this.background,
  });
}

_CategoryPresentation _presentationFor(DriverNotificationCategory category) {
  return switch (category) {
    DriverNotificationCategory.newOrder => _CategoryPresentation(
        icon: Icons.add_box_outlined,
        foreground: AppColors.success,
        background: AppColors.beige.withOpacity(.32),
      ),
    DriverNotificationCategory.orderAcceptedElsewhere =>
      const _CategoryPresentation(
        icon: Icons.group_outlined,
        foreground: AppColors.muted,
        background: AppColors.cream,
      ),
    DriverNotificationCategory.orderUpdated => const _CategoryPresentation(
        icon: Icons.edit_note_rounded,
        foreground: AppColors.info,
        background: AppColors.cream,
      ),
    DriverNotificationCategory.branchReady => _CategoryPresentation(
        icon: Icons.storefront_outlined,
        foreground: AppColors.success,
        background: AppColors.beige.withOpacity(.32),
      ),
    DriverNotificationCategory.customerMessage => const _CategoryPresentation(
        icon: Icons.chat_bubble_outline_rounded,
        foreground: AppColors.info,
        background: AppColors.cream,
      ),
    DriverNotificationCategory.cancellation => const _CategoryPresentation(
        icon: Icons.cancel_outlined,
        foreground: AppColors.danger,
        background: AppColors.cream,
      ),
    DriverNotificationCategory.deliveryVerificationIssue =>
      const _CategoryPresentation(
        icon: Icons.verified_user_outlined,
        foreground: AppColors.warning,
        background: AppColors.cream,
      ),
    DriverNotificationCategory.earnings => _CategoryPresentation(
        icon: Icons.payments_outlined,
        foreground: AppColors.success,
        background: AppColors.beige.withOpacity(.32),
      ),
    DriverNotificationCategory.documentExpiry => const _CategoryPresentation(
        icon: Icons.badge_outlined,
        foreground: AppColors.warning,
        background: AppColors.cream,
      ),
    DriverNotificationCategory.system => const _CategoryPresentation(
        icon: Icons.settings_outlined,
        foreground: AppColors.greenDark,
        background: AppColors.cream,
      ),
  };
}

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
