import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class LiveSocketService {
  StompClient? _client;
  bool _connected = false;
  late String _roomId;
  late String _sender;
  void Function(Map<String, dynamic> msg)? onMessage;

  Future<void> connect({
    required String wsBase,
    required String roomId,
    required String sender,
    Map<String, String>? headers,
  }) async {
    _roomId = roomId;
    _sender = sender;
    final url = '$wsBase/ws/chat/websocket';

    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) {
          _connected = true;
          _client?.subscribe(
            destination: '/topic/room/$_roomId',
            callback: (f) {
              if (f.body == null) return;
              onMessage?.call(jsonDecode(f.body!));
            },
          );
        },
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

  void sendText(String text) {
    if (!_connected) return;
    final body = jsonEncode({
      'roomId': _roomId,
      'sender': _sender,
      'message': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _client?.send(destination: '/app/chat.sendMessage', body: body);
  }

  void disconnect() {
    _client?.deactivate();
    _connected = false;
  }
}
