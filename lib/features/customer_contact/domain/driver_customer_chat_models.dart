const List<String> driverCustomerChatQuickReplies = <String>[
  'I’m arriving soon',
  'I’m outside',
  'Please come down',
  'Please check your phone',
  'I’m at the entrance',
  'Where should I meet you?',
];

enum DriverCustomerChatAuthor { driver, customer, system }

enum DriverCustomerChatDataSource { demo, api }

class DriverCustomerChatMessage {
  final String id;
  final String threadId;
  final DriverCustomerChatAuthor author;
  final String text;
  final DateTime sentAt;

  const DriverCustomerChatMessage({
    required this.id,
    required this.threadId,
    required this.author,
    required this.text,
    required this.sentAt,
  });

  factory DriverCustomerChatMessage.fromJson(Map<String, dynamic> json) {
    final authorName = json['author'] as String? ?? '';
    return DriverCustomerChatMessage(
      id: json['id'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      author: DriverCustomerChatAuthor.values.firstWhere(
        (value) => value.name == authorName,
        orElse: () => DriverCustomerChatAuthor.system,
      ),
      text: json['text'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'threadId': threadId,
        'author': author.name,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };
}

class DriverCustomerChatThread {
  final String threadId;
  final String orderNumber;
  final List<DriverCustomerChatMessage> messages;
  final bool isDemo;

  const DriverCustomerChatThread({
    required this.threadId,
    required this.orderNumber,
    required this.messages,
    required this.isDemo,
  });
}

class DriverCustomerChatResult {
  final DriverCustomerChatThread? thread;
  final String? errorMessage;

  const DriverCustomerChatResult._({this.thread, this.errorMessage});

  const DriverCustomerChatResult.success(DriverCustomerChatThread value)
      : this._(thread: value);

  const DriverCustomerChatResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => thread != null;
}
