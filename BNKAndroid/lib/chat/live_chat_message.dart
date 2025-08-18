class LiveChatMessage {
  final int roomId;
  final String senderType; // 'USER' | 'ADMIN'
  final int? senderId;
  final String message;
  final DateTime? at;

  // 화면 정렬용
  final bool isMine;

  LiveChatMessage({
    required this.roomId,
    required this.senderType,
    this.senderId,
    required this.message,
    required this.at,
    required this.isMine,
  });

  factory LiveChatMessage.fromJson(Map<String, dynamic> j) {
    // 서버 DTO 키 매핑:
    // roomId, senderType('USER'/'ADMIN'), senderId, message, sentAt
    final senderType = (j['senderType'] ?? '').toString().toUpperCase();
    final atStr = (j['sentAt'] ?? j['timestamp'] ?? '') as String?; // 서버가 둘 중 하나 줄 수 있음
    DateTime? at;
    try { if (atStr != null && atStr.isNotEmpty) at = DateTime.parse(atStr); } catch (_) {}

    return LiveChatMessage(
      roomId: (j['roomId'] ?? 0) as int,
      senderType: senderType,
      senderId: (j['senderId'] is int) ? j['senderId'] as int : int.tryParse('${j['senderId'] ?? ''}'),
      message: (j['message'] ?? '').toString(),
      at: at,
      // 규칙: 앱(사용자)은 항상 오른쪽 → senderType == 'USER' 이면 내가 보낸 것
      isMine: senderType == 'USER',
    );
  }
}
