import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_support_chat_models.dart';

abstract interface class DriverSupportChatRepository {
  DriverSupportChatDataSource get source;

  String threadIdFor({String? orderNumber});

  Future<DriverSupportChatResult> loadThread({
    String? orderNumber,
    int? apiOrderId,
  });

  Future<DriverSupportChatResult> sendDriverMessage({
    String? orderNumber,
    int? apiOrderId,
    required String text,
  });
}

class DriverSupportChatRepositoryFactory {
  DriverSupportChatRepositoryFactory._();

  static DriverSupportChatRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverSupportChatRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.allowsDemo
        ? const DemoDriverSupportChatRepository()
        : const UnavailableDriverSupportChatRepository();
  }
}

class ApiDriverSupportChatRepository implements DriverSupportChatRepository {
  final DriverApiContext context;
  const ApiDriverSupportChatRepository(this.context);

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
  Future<DriverSupportChatResult> loadThread({
    String? orderNumber,
    int? apiOrderId,
  }) async {
    try {
      final conversation = await _open(
        orderNumber: orderNumber,
        apiOrderId: apiOrderId,
      );
      return DriverSupportChatResult.success(
        _thread(conversation, orderNumber: orderNumber),
      );
    } on ApiException catch (error) {
      return DriverSupportChatResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverSupportChatResult.failure(error.message);
    }
  }

  @override
  Future<DriverSupportChatResult> sendDriverMessage({
    String? orderNumber,
    int? apiOrderId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const DriverSupportChatResult.failure(
        'Write a message or choose a support topic before sending.',
      );
    }

    try {
      final opened = await _open(
        orderNumber: orderNumber,
        apiOrderId: apiOrderId,
      );
      final conversationId = (opened['id'] as num?)?.toInt();
      if (conversationId == null) {
        throw const FormatException(
          'Support conversation identifier is missing.',
        );
      }
      await context.apiClient.postJson(
        '/v1/driver/conversations/$conversationId/messages',
        authenticated: true,
        body: <String, Object?>{'body': clean},
      );
      final refreshed = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/conversations/$conversationId',
          authenticated: true,
        ),
      );
      return DriverSupportChatResult.success(
        _thread(refreshed, orderNumber: orderNumber),
      );
    } on ApiException catch (error) {
      return DriverSupportChatResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverSupportChatResult.failure(error.message);
    }
  }

  Future<Map<String, dynamic>> _open({
    String? orderNumber,
    int? apiOrderId,
  }) async {
    final cleanOrder = orderNumber?.trim();
    return DriverApiContext.dataMap(
      await context.apiClient.postJson(
        '/v1/driver/support-conversations',
        authenticated: true,
        body: <String, Object?>{
          if (apiOrderId != null) 'order_id': apiOrderId,
          'subject': cleanOrder == null || cleanOrder.isEmpty
              ? 'Driver app support'
              : 'Order $cleanOrder support',
        },
      ),
    );
  }

  DriverSupportChatThread _thread(
    Map<String, dynamic> raw, {
    String? orderNumber,
  }) {
    final id = raw['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FormatException(
          'Support conversation identifier is missing.');
    }
    final list = raw['messages'];
    final messages = list is List
        ? list
            .whereType<Map>()
            .map((entry) => _message(
                  Map<String, dynamic>.from(entry),
                  threadId: id,
                ))
            .toList()
        : <DriverSupportChatMessage>[];
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    final clean = orderNumber?.trim();
    return DriverSupportChatThread(
      threadId: id,
      orderNumber: clean == null || clean.isEmpty ? null : clean,
      messages: List<DriverSupportChatMessage>.unmodifiable(messages),
      isDemo: false,
    );
  }

  DriverSupportChatMessage _message(
    Map<String, dynamic> raw, {
    required String threadId,
  }) {
    final sender = raw['sender'] is Map
        ? Map<String, dynamic>.from(raw['sender'] as Map)
        : const <String, dynamic>{};
    final type = sender['user_type']?.toString().toLowerCase();
    return DriverSupportChatMessage(
      id: raw['id']?.toString() ?? '',
      threadId: threadId,
      author: type == 'driver'
          ? DriverSupportChatAuthor.driver
          : (type == null
              ? DriverSupportChatAuthor.system
              : DriverSupportChatAuthor.support),
      text: raw['body']?.toString() ?? '',
      sentAt: DateTime.tryParse(raw['sent_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
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
  Future<DriverSupportChatResult> loadThread(
      {String? orderNumber, int? apiOrderId}) async {
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
    int? apiOrderId,
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
    if (raw == null || raw.trim().isEmpty) {
      return <DriverSupportChatMessage>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <DriverSupportChatMessage>[];
      }
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
  Future<DriverSupportChatResult> loadThread(
      {String? orderNumber, int? apiOrderId}) async {
    return const DriverSupportChatResult.failure(
      'Getin Support chat is not connected to Laravel yet. No support conversation was created.',
    );
  }

  @override
  Future<DriverSupportChatResult> sendDriverMessage({
    String? orderNumber,
    int? apiOrderId,
    required String text,
  }) async {
    return const DriverSupportChatResult.failure(
      'Getin Support chat is not connected to Laravel yet. Your message was not sent.',
    );
  }
}
