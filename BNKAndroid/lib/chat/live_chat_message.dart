// lib/chat/live_chat_message.dart
class LiveChatMessage {
  final int roomId;
  final String sender;   // username 또는 'admin'
  final String message;
  final DateTime at;

  LiveChatMessage({
    required this.roomId,
    required this.sender,
    required this.message,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  factory LiveChatMessage.fromJson(Map<String, dynamic> j) {
    return LiveChatMessage(
      roomId: j['roomId'] is int ? j['roomId'] : int.tryParse('${j['roomId']}') ?? 0,
      sender: j['sender']?.toString() ?? 'unknown',
      message: j['message']?.toString() ?? '',
      at: DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'sender': sender,
    'message': message,
    'timestamp': at.toIso8601String(),
  };
}
