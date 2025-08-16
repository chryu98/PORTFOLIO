
// lib/chat/widgets/chat_message.dart
class ChatMessage {
  final bool fromUser;
  final String text;
  final DateTime at;

  ChatMessage({
    required this.fromUser,
    required this.text,
    DateTime? at,
  }) : at = at ?? DateTime.now();
}