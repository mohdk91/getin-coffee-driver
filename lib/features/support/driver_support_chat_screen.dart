import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_support_chat_repository.dart';
import 'domain/driver_support_chat_models.dart';

class DriverSupportChatScreen extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary? delivery;
  final String? contextOrderNumber;
  final String? initialDraft;
  final DriverSupportChatRepository? repository;

  const DriverSupportChatScreen({
    super.key,
    required this.config,
    this.delivery,
    this.contextOrderNumber,
    this.initialDraft,
    this.repository,
  });

  String? get orderNumber {
    final fromDelivery = delivery?.orderNumber.trim();
    if (fromDelivery != null && fromDelivery.isNotEmpty) return fromDelivery;
    final fromContext = contextOrderNumber?.trim();
    return fromContext == null || fromContext.isEmpty ? null : fromContext;
  }

  @override
  State<DriverSupportChatScreen> createState() =>
      _DriverSupportChatScreenState();
}

class _DriverSupportChatScreenState extends State<DriverSupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DriverSupportChatRepository _repository = widget.repository ??
      DriverSupportChatRepositoryFactory.create(widget.config);

  DriverSupportChatThread? _thread;
  String? _errorMessage;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft?.trim();
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final result =
        await _repository.loadThread(orderNumber: widget.orderNumber);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _thread = result.thread;
      _errorMessage = result.errorMessage;
    });
    _scheduleScroll();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _sendText(text);
  }

  Future<void> _sendQuickTopic(String topic) async {
    await _sendText(topic);
  }

  Future<void> _sendText(String text) async {
    if (_sending) return;
    final clean = text.trim();
    if (clean.isEmpty) return;

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    final result = await _repository.sendDriverMessage(
      orderNumber: widget.orderNumber,
      text: clean,
    );
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (result.thread != null) _thread = result.thread;
      _errorMessage = result.errorMessage;
    });
    _scheduleScroll();
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = widget.orderNumber;
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Getin Support',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              orderNumber == null ? 'Operations support' : 'Order $orderNumber',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (orderNumber != null)
              _OrderContextBar(
                orderNumber: orderNumber,
                delivery: widget.delivery,
              ),
            if (_repository.source == DriverSupportChatDataSource.demo)
              const _DemoNotice(),
            Expanded(
              child: _buildConversation(padding),
            ),
            _QuickTopics(
              disabled: _sending || _thread == null,
              onSelected: _sendQuickTopic,
            ),
            _Composer(
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(double padding) {
    if (_loading && _thread == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final thread = _thread;
    if (thread == null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(padding, 24, padding, 24),
        children: [
          _ErrorCard(
            message: _errorMessage ?? 'Support chat is unavailable.',
            onRetry: _load,
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(padding, 18, padding, 18),
      itemCount: thread.messages.length + (_errorMessage == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == thread.messages.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _ErrorCard(message: _errorMessage!, onRetry: _load),
          );
        }
        final message = thread.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MessageBubble(message: message),
        );
      },
    );
  }
}

class _OrderContextBar extends StatelessWidget {
  final String orderNumber;
  final DriverActiveDeliverySummary? delivery;

  const _OrderContextBar({required this.orderNumber, this.delivery});

  @override
  Widget build(BuildContext context) {
    final details = delivery == null
        ? 'Order-linked support thread'
        : '${delivery!.pickupBranch} → ${delivery!.destinationArea} • ${delivery!.status}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
      color: AppColors.greenDark,
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.beige, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order $orderNumber',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      color: const Color(0xFFFFF8E8),
      child: const Text(
        'DEMO SUPPORT CHAT • Stored locally only • Not connected to Getin operations',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuickTopics extends StatelessWidget {
  final bool disabled;
  final ValueChanged<String> onSelected;

  const _QuickTopics({required this.disabled, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick topics',
            style: TextStyle(
              color: AppColors.greenDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final topic in driverSupportQuickTopics)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ActionChip(
                      key: ValueKey<String>('support-quick-topic:$topic'),
                      label: Text(topic),
                      onPressed: disabled ? null : () => onSelected(topic),
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

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Message Getin Support…',
                isDense: true,
              ),
              onSubmitted: (_) {
                if (!sending) onSend();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: sending ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.beige,
            ),
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DriverSupportChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.author == DriverSupportChatAuthor.system) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.border.withOpacity(.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final driver = message.author == DriverSupportChatAuthor.driver;
    return Align(
      alignment: driver ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
        decoration: BoxDecoration(
          color: driver ? AppColors.greenDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: driver ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!driver) ...[
              const Text(
                'Getin Support',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: driver ? AppColors.white : AppColors.greenDark,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.sentAt),
              style: TextStyle(
                color: driver ? AppColors.beige : AppColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
