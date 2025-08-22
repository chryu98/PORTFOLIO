class PushMessage {
  final String title;
  final String content;
  final DateTime receivedAt;
  PushMessage(this.title, this.content) : receivedAt = DateTime.now();
}