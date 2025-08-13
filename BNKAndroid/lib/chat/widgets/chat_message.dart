// lib/chat/widgets/chat_message.dart
class ChatMessage {
  final String role;     // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime ts;

  ChatMessage({required this.role, required this.content, DateTime? ts})
      : ts = ts ?? DateTime.now();
}
