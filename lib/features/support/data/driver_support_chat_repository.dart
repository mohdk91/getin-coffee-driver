import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_support_chat_models.dart';

abstract interface class DriverSupportChatRepository {
  DriverSupportChatDataSource get source;

  String threadIdFor({String? orderNumber});

  Future<DriverSupportChatResult> loadThread({String? orderNumber});

  Future<DriverSupportChatResult> sendDriverMessage({
    String? orderNumber,
    required String text,
  });
}

class DriverSupportChatRepositoryFactory {
  DriverSupportChatRepositoryFactory._();

  static DriverSupportChatRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverSupportChatRepository()
        : const UnavailableDriverSupportChatRepository();
  }
}

class DemoDriverSupportChatRepository implements DriverSupportChatRepository {
  const DemoDriverSupportChatRepository();

  static const String _storagePrefix = 'getin_driver_demo_support_chat_v1:';

  @override
  DriverSupportChatDataSource get source => DriverSupportChatDataSource.demo;

  @override
  String threadIdFor({String? orderNumber}) {
    final clean = orderNumber?.trim();
    return clean == null || clean.isEmpty
        ? 'support:general'
        : 'support:order:$clean';
  }

  String _storageKey(String? orderNumber) =>
      '$_storagePrefix${threadIdFor(orderNumber: orderNumber)}';

  @override
  Future<DriverSupportChatResult> loadThread({String? orderNumber}) async {
    final preferences = await SharedPreferences.getInstance();
    var messages = _readMessages(preferences, orderNumber);
    if (messages.isEmpty) {
      messages = _seedMessages(orderNumber);
      await _persist(preferences, orderNumber, messages);
    }

    return DriverSupportChatResult.success(
      DriverSupportChatThread(
        threadId: threadIdFor(orderNumber: orderNumber),
        orderNumber: _normalizedOrderNumber(orderNumber),
        messages: List<DriverSupportChatMessage>.unmodifiable(messages),
        isDemo: true,
      ),
    );
  }

  @override
  Future<DriverSupportChatResult> sendDriverMessage({
    String? orderNumber,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const DriverSupportChatResult.failure(
        'Write a message or choose a support topic before sending.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    var messages = _readMessages(preferences, orderNumber);
    if (messages.isEmpty) {
      messages = _seedMessages(orderNumber);
    }

    final now = DateTime.now();
    final threadId = threadIdFor(orderNumber: orderNumber);
    messages.add(
      DriverSupportChatMessage(
        id: '${now.microsecondsSinceEpoch}-driver',
        threadId: threadId,
        author: DriverSupportChatAuthor.driver,
        text: clean,
        sentAt: now,
      ),
    );
    messages.add(
      DriverSupportChatMessage(
        id: '${now.microsecondsSinceEpoch}-support',
        threadId: threadId,
        author: DriverSupportChatAuthor.support,
        text: _demoAcknowledgement(orderNumber),
        sentAt: now.add(const Duration(seconds: 1)),
      ),
    );
    await _persist(preferences, orderNumber, messages);

    return DriverSupportChatResult.success(
      DriverSupportChatThread(
        threadId: threadId,
        orderNumber: _normalizedOrderNumber(orderNumber),
        messages: List<DriverSupportChatMessage>.unmodifiable(messages),
        isDemo: true,
      ),
    );
  }

  String? _normalizedOrderNumber(String? orderNumber) {
    final clean = orderNumber?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  List<DriverSupportChatMessage> _readMessages(
    SharedPreferences preferences,
    String? orderNumber,
  ) {
    final raw = preferences.getString(_storageKey(orderNumber));
    if (raw == null || raw.trim().isEmpty) return <DriverSupportChatMessage>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <DriverSupportChatMessage>[];
      final threadId = threadIdFor(orderNumber: orderNumber);
      final messages = decoded
          .whereType<Map>()
          .map(
            (entry) => DriverSupportChatMessage.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (message) =>
                message.threadId == threadId && message.text.trim().isNotEmpty,
          )
          .toList();
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return messages;
    } catch (_) {
      return <DriverSupportChatMessage>[];
    }
  }

  List<DriverSupportChatMessage> _seedMessages(String? orderNumber) {
    final threadId = threadIdFor(orderNumber: orderNumber);
    final cleanOrder = _normalizedOrderNumber(orderNumber);
    final now = DateTime.now();
    return <DriverSupportChatMessage>[
      DriverSupportChatMessage(
        id: 'demo-system-$threadId',
        threadId: threadId,
        author: DriverSupportChatAuthor.system,
        text: cleanOrder == null
            ? 'Local demo support chat. No message is sent to Getin operations.'
            : 'Local demo support chat for order $cleanOrder. No message is sent to Getin operations.',
        sentAt: now.subtract(const Duration(minutes: 2)),
      ),
      DriverSupportChatMessage(
        id: 'demo-support-$threadId',
        threadId: threadId,
        author: DriverSupportChatAuthor.support,
        text: cleanOrder == null
            ? 'Hi, this is Getin Support demo. Choose a topic or describe what you need help with.'
            : 'Hi, this is Getin Support demo. I can see the context for order $cleanOrder. Choose a topic or describe the issue.',
        sentAt: now.subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  String _demoAcknowledgement(String? orderNumber) {
    final cleanOrder = _normalizedOrderNumber(orderNumber);
    return cleanOrder == null
        ? 'Demo acknowledgement: your support message is stored on this device only. A real operations agent will reply after Laravel support is connected.'
        : 'Demo acknowledgement for $cleanOrder: your message is stored on this device only. A real operations agent will reply after Laravel support is connected.';
  }

  Future<void> _persist(
    SharedPreferences preferences,
    String? orderNumber,
    List<DriverSupportChatMessage> messages,
  ) async {
    await preferences.setString(
      _storageKey(orderNumber),
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );
  }
}

class UnavailableDriverSupportChatRepository
    implements DriverSupportChatRepository {
  const UnavailableDriverSupportChatRepository();

  @override
  DriverSupportChatDataSource get source => DriverSupportChatDataSource.api;

  @override
  String threadIdFor({String? orderNumber}) {
    final clean = orderNumber?.trim();
    return clean == null || clean.isEmpty
        ? 'support:general'
        : 'support:order:$clean';
  }

  @override
  Future<DriverSupportChatResult> loadThread({String? orderNumber}) async {
    return const DriverSupportChatResult.failure(
      'Getin Support chat is not connected to Laravel yet. No support conversation was created.',
    );
  }

  @override
  Future<DriverSupportChatResult> sendDriverMessage({
    String? orderNumber,
    required String text,
  }) async {
    return const DriverSupportChatResult.failure(
      'Getin Support chat is not connected to Laravel yet. Your message was not sent.',
    );
  }
}
