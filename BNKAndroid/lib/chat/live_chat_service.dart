import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'package:bnkandroid/constants/api.dart';
import '../models/live_chat_message.dart';
import '../widgets/authorized_client_bridge.dart'; // 아래 2-1 참고(간단 브릿지)

class LiveChatService {
  StompClient? _stomp;
  String? _token;

  Future<String?> _loadToken() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('jwt_token');
    return (t != null && t.isNotEmpty) ? t : null;
  }

  Future<List<LiveChatMessage>> fetchHistoryAll(int roomId) async {
    // AuthorizedClient를 그대로 쓰고 싶다면 아래 주석 해제하고 사용:
    // final resp = await AuthorizedClient.get('${API.baseUrl}/api/chat/messages/$roomId');

    // AuthorizedClient가 현재 스코프에 없다면 임시로 직접 호출:
    final t = await _loadToken();
    final resp = await http.get(
      Uri.parse('${API.baseUrl}/api/chat/messages/$roomId'),
      headers: {'Authorization': 'Bearer $t'},
    );

    if (resp.statusCode != 200) {
      throw Exception('히스토리 로드 실패: ${resp.statusCode}');
    }
    final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
    return list
        .map((e) => LiveChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> connect({
    required String wsBase, // 예: 'ws://192.168.0.5:8090'
    required int roomId,
    required void Function(LiveChatMessage) onMessage,
  }) async {
    _token = await _loadToken();

    _stomp = StompClient(
      config: StompConfig.sockJS(
        url: '$wsBase/ws/chat',
        stompConnectHeaders: {'Authorization': 'Bearer ${_token ?? ''}'},
        webSocketConnectHeaders: {'Authorization': 'Bearer ${_token ?? ''}'},
        onConnect: (_) {
          _stomp?.subscribe(
            destination: '/topic/room/$roomId',
            headers: {'Authorization': 'Bearer ${_token ?? ''}'},
            callback: (StompFrame f) {
              final body = f.body ?? '';
              if (body.isEmpty) return;
              final obj = jsonDecode(body) as Map<String, dynamic>;
              onMessage(LiveChatMessage.fromJson(obj));
            },
          );
        },
        onWebSocketError: (e) => print('STOMP error: $e'),
      ),
    );

    _stomp?.activate();
  }

  void send(LiveChatMessage m) {
    _stomp?.send(
      destination: '/app/chat.sendMessage',
      headers: {'Authorization': 'Bearer ${_token ?? ''}'},
      body: jsonEncode(m.toJson()),
    );
  }

  void disconnect() => _stomp?.deactivate();
}
