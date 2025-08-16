// lib/chat/live_socket_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// 한 줄만 사용하되 별칭으로 고정 (충돌/IDE 꼬임 방지)
import 'package:stomp_dart_client/stomp_dart_client.dart' as stomp;

typedef OnLiveMessage = void Function(Map<String, dynamic> body);

class LiveSocketService {
  stomp.StompClient? _stomp;
  String? _token;
  String? _username;

  Future<void> _loadAuth() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('jwt_token');
    _username = sp.getString('username');
  }

  bool get connected => _stomp?.connected ?? false;

  Future<void> connect({
    required int roomId,
    required OnLiveMessage onMessage,
    String url = 'ws://192.168.35.123:8090/ws-stomp/websocket',
  }) async {
    if (connected) return;
    await _loadAuth();

    final headers = <String, String>{
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      if (_username != null && _username!.isNotEmpty) 'X-Username': _username!,
    };

    _stomp = stomp.StompClient(
      config: stomp.StompConfig(
        url: url,
        onConnect: (stomp.StompFrame frame) {
          _stomp?.subscribe(
            destination: '/topic/room/$roomId',
            headers: headers,
            callback: (stomp.StompFrame f) {
              final body = f.body;
              if (body != null) {
                try {
                  final m = jsonDecode(body);
                  onMessage(m is Map<String, dynamic> ? m : {'raw': body});
                } catch (_) {
                  onMessage({'raw': body});
                }
              }
            },
          );
        },
        onWebSocketError: (e) => print('STOMP error: $e'),
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        heartbeatOutgoing: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 5),
        reconnectDelay: const Duration(milliseconds: 800),
      ),
    );

    _stomp!.activate();
  }

  void sendToRoom(int roomId, Map<String, dynamic> payload) {
    if (!connected) return;
    _stomp!.send(
      destination: '/app/chat.send/$roomId',
      body: jsonEncode(payload),
    );
  }

  void disconnect() {
    _stomp?.deactivate(); // void 반환 → await 제거
    _stomp = null;
  }
}
