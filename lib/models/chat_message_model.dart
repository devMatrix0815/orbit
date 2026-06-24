class ChatMessage {
  final String id;
  final String circleId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String? senderProfileImageBase64;
  final String? senderProfileImageUrl;
  final List<String> senderBadges;
  final MessageType type;
  final String? widgetHtml;
  final Map<String, dynamic>? widgetState;
  final String? widgetType;

  ChatMessage({
    required this.id,
    required this.circleId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.senderProfileImageBase64,
    this.senderProfileImageUrl,
    this.senderBadges = const [],
    this.type = MessageType.text,
    this.widgetHtml,
    this.widgetState,
    this.widgetType,
  });

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'senderProfileImageBase64': senderProfileImageBase64,
      'senderProfileImageUrl': senderProfileImageUrl,
      'senderBadges': senderBadges,
      'type': type.name,
      if (widgetHtml != null) 'widgetHtml': widgetHtml,
      if (widgetState != null) 'widgetState': widgetState,
      if (widgetType != null) 'widgetType': widgetType,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      circleId: map['circleId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      ).toLocal(),
      senderProfileImageBase64: map['senderProfileImageBase64'],
      senderProfileImageUrl: map['senderProfileImageUrl'],
      senderBadges: List<String>.from(map['senderBadges'] ?? []),
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      widgetHtml: map['widgetHtml'],
      widgetState: map['widgetState'] != null
          ? Map<String, dynamic>.from(map['widgetState'])
          : null,
      widgetType: map['widgetType'],
    );
  }
}

enum MessageType { text, system, widget }
