import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_customer_chat_repository.dart';
import 'domain/driver_customer_chat_models.dart';

class DriverCustomerChatScreen extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary delivery;
  final DriverCustomerChatRepository? repository;

  const DriverCustomerChatScreen({
    super.key,
    required this.config,
    required this.delivery,
    this.repository,
  });

  @override
  State<DriverCustomerChatScreen> createState() =>
      _DriverCustomerChatScreenState();
}

class _DriverCustomerChatScreenState extends State<DriverCustomerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DriverCustomerChatRepository _repository = widget.repository ??
      DriverCustomerChatRepositoryFactory.create(widget.config);

  DriverCustomerChatThread? _thread;
  String? _errorMessage;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
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

    final result = await _repository.loadThread(
      orderNumber: widget.delivery.orderNumber,
      apiOrderId: widget.delivery.apiOrderId,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _thread = result.thread;
      _errorMessage = result.errorMessage;
    });
    _scheduleScroll();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _controller.clear();
    await _sendText(text);
  }

  Future<void> _sendQuickReply(String text) async {
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    if (_sending) {
      return;
    }
    final clean = text.trim();
    if (clean.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    final result = await _repository.sendDriverMessage(
      orderNumber: widget.delivery.orderNumber,
      apiOrderId: widget.delivery.apiOrderId,
      text: clean,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _sending = false;
      if (result.thread != null) {
        _thread = result.thread;
      }
      _errorMessage = result.errorMessage;
    });
    _scheduleScroll();
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Order ${widget.delivery.orderNumber}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ChatContextCard(
              delivery: widget.delivery,
              isDemo: _repository.source == DriverCustomerChatDataSource.demo,
            ),
            Expanded(child: _buildConversation()),
            _Composer(
              controller: _controller,
              sending: _sending,
              quickReplies: driverCustomerChatQuickReplies,
              onQuickReply: _sendQuickReply,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_thread == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.muted,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Customer chat is unavailable.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final messages = _thread!.messages;
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8BABA)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              8,
              Responsive.horizontalPadding(context),
              16,
            ),
            itemCount: messages.length,
            itemBuilder: (context, index) =>
                _ChatBubble(message: messages[index]),
          ),
        ),
      ],
    );
  }
}

class _ChatContextCard extends StatelessWidget {
  final DriverActiveDeliverySummary delivery;
  final bool isDemo;

  const _ChatContextCard({required this.delivery, required this.isDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.beige,
            child: Icon(Icons.person_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer contact',
                  style: TextStyle(
                    color: AppColors.beige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDemo
                      ? 'Local demo order chat · messages stay on this device'
                      : 'Order-specific customer chat',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${delivery.orderNumber} · ${delivery.destinationArea}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

class _ChatBubble extends StatelessWidget {
  final DriverCustomerChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.author == DriverCustomerChatAuthor.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10.5,
            height: 1.35,
          ),
        ),
      );
    }

    final mine = message.author == DriverCustomerChatAuthor.driver;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: mine ? const Radius.circular(5) : null,
            bottomLeft: mine ? null : const Radius.circular(5),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: mine ? Colors.white : AppColors.green,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final List<String> quickReplies;
  final ValueChanged<String> onQuickReply;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.quickReplies,
    required this.onQuickReply,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: AppColors.green,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Quick replies',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final reply in quickReplies)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ActionChip(
                        key: ValueKey<String>('customer-quick-reply:$reply'),
                        onPressed: sending ? null : () => onQuickReply(reply),
                        avatar: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 15,
                        ),
                        label: Text(reply),
                        labelStyle: const TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        backgroundColor: AppColors.cream,
                        side: const BorderSide(color: AppColors.border),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Message customer',
                      filled: true,
                      fillColor: AppColors.cream,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.beige,
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.beige,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
