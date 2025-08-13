// lib/chat/chat_socket_service.dart
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatSocketService {
  StompClient? _client;
  bool _connected = false;

  late String _roomId;
  late String _sender;

  // 메시지 수신 콜백 주입 방식 (UI에서 등록)
  void Function(Map<String, dynamic> msg)? onMessage;

  /// wsBase 예: ws://192.168.0.5:8090
  Future<void> connect({
    required String wsBase,
    required String roomId,
    required String sender,
    Map<String, String>? headers,
  }) async {
    _roomId = roomId;
    _sender = sender;

    // SockJS endpoint는 '/ws/chat', 실제 WS는 '/ws/chat/websocket'
    final url = '$wsBase/ws/chat/websocket';

    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: _onConnect,
        onStompError: (f) => print('STOMP error: ${f.body}'),
        onWebSocketError: (e) => print('WS error: $e'),
        stompConnectHeaders: headers ?? {},
        webSocketConnectHeaders: headers ?? {},
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        connectionTimeout: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;

    // 서버 config: enableSimpleBroker("/topic")
    // 구독 경로
    _client?.subscribe(
      destination: '/topic/room/$_roomId',
      callback: (StompFrame f) {
        if (f.body == null) return;
        final data = jsonDecode(f.body!);
        onMessage?.call(data);
      },
    );
  }

  void sendText(String text) {
    if (!_connected) return;
    final body = jsonEncode({
      'roomId': _roomId,
      'sender': _sender,
      'message': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // 서버 @MessageMapping("/chat.sendMessage") + setApplicationDestinationPrefixes("/app")
    _client?.send(destination: '/app/chat.sendMessage', body: body);
  }

  void disconnect() {
    _client?.deactivate();
    _connected = false;
  }
}
