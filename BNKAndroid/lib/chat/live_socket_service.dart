// lib/chat/live_socket_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart' as stomp;

typedef OnLiveMessage = void Function(Map<String, dynamic> body);

class LiveSocketService {
  stomp.StompClient? _stomp;
  String? _token;
  String? _username;
  int? _memberNo;

  Future<void> _loadAuth() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('jwt_token');
    _username = sp.getString('username');         // (선택) 화면 표시용
    _memberNo = sp.getInt('member_no');           // ★ 반드시 저장되어 있어야 함
  }

  bool get connected => _stomp?.connected ?? false;

  Future<void> connect({
    required int roomId,
    required OnLiveMessage onMessage,
    // 표준 WS 엔드포인트 (SockJS 아님)
    String url = 'ws://192.168.0.5:8090/ws/chat',
  }) async {
    if (connected) return;
    await _loadAuth();

    final headers = <String, String>{
      if (_token?.isNotEmpty == true) 'Authorization': 'Bearer $_token',
      if (_username?.isNotEmpty == true) 'X-Username': _username!,
      if (_memberNo != null) 'X-Member-No': _memberNo.toString(),
    };

    _stomp = stomp.StompClient(
      config: stomp.StompConfig(
        url: url,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (_) {
          _stomp?.subscribe(
            destination: '/topic/room/$roomId',
            headers: headers,
            callback: (f) {
              final b = f.body;
              if (b == null) return;
              try {
                final m = jsonDecode(b);
                onMessage(m is Map<String, dynamic> ? m : {'raw': b});
              } catch (_) {
                onMessage({'raw': b});
              }
            },
          );
        },
        onWebSocketError: (e) => print('💥 WebSocket error: $e'),
        heartbeatOutgoing: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 5),
        reconnectDelay: const Duration(milliseconds: 1200),
      ),
    );

    _stomp!.activate();
  }

  /// 서버 DTO와 정확히 일치하는 키로 전송
  /// ChatMessageDto: roomId, senderType, senderId, message, sentAt(Date)
  void sendToRoom(int roomId, Map<String, dynamic> payload) {
    if (!connected) {
      print('⚠️ STOMP not connected');
      return;
    }
    final nowIso = DateTime.now().toIso8601String();

    final body = <String, dynamic>{
      'roomId': roomId,
      'senderType': 'USER',                    // ★ NOT NULL
      'senderId': _memberNo ?? 0,              // ★ NOT NULL
      'message': (payload['message'] ?? payload['text'] ?? '').toString(),
      'sentAt': nowIso,                        // DTO의 Date 필드명과 맞춤
      // 'sender' 같은 화면용 필드는 DTO에 없으니 생략
    };

    _stomp!.send(
      destination: '/app/chat.sendMessage',    // 서버 @MessageMapping 과 동일
      body: jsonEncode(body),
      headers: { if (_token?.isNotEmpty == true) 'Authorization': 'Bearer $_token' },
    );
  }

  void disconnect() {
    _stomp?.deactivate();
    _stomp = null;
  }
}
