const List<String> driverSupportQuickTopics = <String>[
  'Pickup issue',
  'Customer unavailable',
  'Address issue',
  'Payment/verification issue',
  'Damaged package',
  'Safety issue',
  'Talk to operations',
];

enum DriverSupportChatAuthor { driver, support, system }

enum DriverSupportChatDataSource { demo, api }

class DriverSupportChatMessage {
  final String id;
  final String threadId;
  final DriverSupportChatAuthor author;
  final String text;
  final DateTime sentAt;

  const DriverSupportChatMessage({
    required this.id,
    required this.threadId,
    required this.author,
    required this.text,
    required this.sentAt,
  });

  factory DriverSupportChatMessage.fromJson(Map<String, dynamic> json) {
    final authorName = json['author'] as String? ?? '';
    return DriverSupportChatMessage(
      id: json['id'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      author: DriverSupportChatAuthor.values.firstWhere(
        (value) => value.name == authorName,
        orElse: () => DriverSupportChatAuthor.system,
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

class DriverSupportChatThread {
  final String threadId;
  final String? orderNumber;
  final List<DriverSupportChatMessage> messages;
  final bool isDemo;

  const DriverSupportChatThread({
    required this.threadId,
    required this.orderNumber,
    required this.messages,
    required this.isDemo,
  });
}

class DriverSupportChatResult {
  final DriverSupportChatThread? thread;
  final String? errorMessage;

  const DriverSupportChatResult._({this.thread, this.errorMessage});

  const DriverSupportChatResult.success(DriverSupportChatThread value)
      : this._(thread: value);

  const DriverSupportChatResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => thread != null;
}
