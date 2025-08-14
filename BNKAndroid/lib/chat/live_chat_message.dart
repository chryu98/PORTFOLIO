class LiveChatMessage {
  final int roomId;
  final String senderType; // 'USER' | 'ADMIN'
  final int senderId;
  final String message;
  final DateTime sentAt;

  LiveChatMessage({
    required this.roomId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.sentAt,
  });

  factory LiveChatMessage.fromJson(Map<String, dynamic> j) => LiveChatMessage(
    roomId: (j['roomId'] as num).toInt(),
    senderType: j['senderType'] as String,
    senderId: (j['senderId'] as num).toInt(),
    message: (j['message'] ?? '') as String,
    sentAt: DateTime.parse(j['sentAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'senderType': senderType,
    'senderId': senderId,
    'message': message,
    'sentAt': sentAt.toIso8601String(),
  };
}
