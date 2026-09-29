import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_customer_chat_models.dart';

abstract interface class DriverCustomerChatRepository {
  DriverCustomerChatDataSource get source;

  String threadIdFor(String orderNumber);

  Future<DriverCustomerChatResult> loadThread({
    required String orderNumber,
  });

  Future<DriverCustomerChatResult> sendDriverMessage({
    required String orderNumber,
    required String text,
  });
}

class DriverCustomerChatRepositoryFactory {
  DriverCustomerChatRepositoryFactory._();

  static DriverCustomerChatRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverCustomerChatRepository()
        : const UnavailableDriverCustomerChatRepository();
  }
}

class DemoDriverCustomerChatRepository implements DriverCustomerChatRepository {
  const DemoDriverCustomerChatRepository();

  static const String _storagePrefix = 'getin_driver_demo_customer_chat_v1:';

  @override
  DriverCustomerChatDataSource get source => DriverCustomerChatDataSource.demo;

  @override
  String threadIdFor(String orderNumber) => 'driver:$orderNumber';

  String _storageKey(String orderNumber) => '$_storagePrefix$orderNumber';

  @override
  Future<DriverCustomerChatResult> loadThread({
    required String orderNumber,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    var messages = _readMessages(preferences, orderNumber);
    if (messages.isEmpty) {
      messages = _seedMessages(orderNumber);
      await _persist(preferences, orderNumber, messages);
    }
    return DriverCustomerChatResult.success(
      DriverCustomerChatThread(
        threadId: threadIdFor(orderNumber),
        orderNumber: orderNumber,
        messages: List<DriverCustomerChatMessage>.unmodifiable(messages),
        isDemo: true,
      ),
    );
  }

  @override
  Future<DriverCustomerChatResult> sendDriverMessage({
    required String orderNumber,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const DriverCustomerChatResult.failure(
        'Write a message before sending.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    var messages = _readMessages(preferences, orderNumber);
    if (messages.isEmpty) {
      messages = _seedMessages(orderNumber);
    }

    final now = DateTime.now();
    messages.add(
      DriverCustomerChatMessage(
        id: '${now.microsecondsSinceEpoch}-${messages.length}',
        threadId: threadIdFor(orderNumber),
        author: DriverCustomerChatAuthor.driver,
        text: clean,
        sentAt: now,
      ),
    );
    await _persist(preferences, orderNumber, messages);

    return DriverCustomerChatResult.success(
      DriverCustomerChatThread(
        threadId: threadIdFor(orderNumber),
        orderNumber: orderNumber,
        messages: List<DriverCustomerChatMessage>.unmodifiable(messages),
        isDemo: true,
      ),
    );
  }

  List<DriverCustomerChatMessage> _readMessages(
    SharedPreferences preferences,
    String orderNumber,
  ) {
    final raw = preferences.getString(_storageKey(orderNumber));
    if (raw == null || raw.trim().isEmpty) return <DriverCustomerChatMessage>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <DriverCustomerChatMessage>[];
      final messages = decoded
          .whereType<Map>()
          .map(
            (entry) => DriverCustomerChatMessage.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (message) =>
                message.threadId == threadIdFor(orderNumber) &&
                message.text.trim().isNotEmpty,
          )
          .toList();
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return messages;
    } catch (_) {
      return <DriverCustomerChatMessage>[];
    }
  }

  List<DriverCustomerChatMessage> _seedMessages(String orderNumber) {
    final threadId = threadIdFor(orderNumber);
    final now = DateTime.now();
    return <DriverCustomerChatMessage>[
      DriverCustomerChatMessage(
        id: 'demo-system-$orderNumber',
        threadId: threadId,
        author: DriverCustomerChatAuthor.system,
        text:
            'Order-specific demo chat. Avoid sharing passwords or payment details.',
        sentAt: now.subtract(const Duration(minutes: 2)),
      ),
      DriverCustomerChatMessage(
        id: 'demo-customer-$orderNumber',
        threadId: threadId,
        author: DriverCustomerChatAuthor.customer,
        text: 'Please message me when you arrive.',
        sentAt: now.subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  Future<void> _persist(
    SharedPreferences preferences,
    String orderNumber,
    List<DriverCustomerChatMessage> messages,
  ) async {
    await preferences.setString(
      _storageKey(orderNumber),
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );
  }
}

class UnavailableDriverCustomerChatRepository
    implements DriverCustomerChatRepository {
  const UnavailableDriverCustomerChatRepository();

  @override
  DriverCustomerChatDataSource get source => DriverCustomerChatDataSource.api;

  @override
  String threadIdFor(String orderNumber) => 'driver:$orderNumber';

  @override
  Future<DriverCustomerChatResult> loadThread({
    required String orderNumber,
  }) async {
    return const DriverCustomerChatResult.failure(
      'Customer chat is not connected to Laravel yet. No conversation was created.',
    );
  }

  @override
  Future<DriverCustomerChatResult> sendDriverMessage({
    required String orderNumber,
    required String text,
  }) async {
    return const DriverCustomerChatResult.failure(
      'Customer chat is not connected to Laravel yet. Your message was not sent.',
    );
  }
}
