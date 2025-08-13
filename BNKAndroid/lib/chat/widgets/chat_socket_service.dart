// lib/chat/widgets/chat_socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../constants/chat_api.dart';
import 'chat_message.dart';

class ChatSocketService {
  WebSocketChannel? _ch;
  final _incoming = StreamController<ChatMessage>.broadcast();
  bool _connecting = false;

  Stream<ChatMessage> get stream => _incoming.stream;

  Future<void> ensureConnected() async {
    if (_ch != null || _connecting) return;
    _connecting = true;
    try {
      // FastAPI에 /ws가 없으면 여기서 실패 → HTTP 폴백으로만 동작
      _ch = WebSocketChannel.connect(ChatAPI.ws());
      _ch!.stream.listen((data) {
        _incoming.add(ChatMessage(role: 'assistant', content: data.toString()));
      }, onError: (_) {
        _disposeSocket();
      }, onDone: () {
        _disposeSocket();
      });
    } catch (_) {
      _disposeSocket();
    } finally {
      _connecting = false;
    }
  }

  Future<void> send(String text) async {
    // 사용자 메시지 즉시 반영
    _incoming.add(ChatMessage(role: 'user', content: text));

    // 소켓 연결 시 소켓 우선
    if (_ch != null) {
      try {
        _ch!.sink.add(text);
        return;
      } catch (_) {
        _disposeSocket();
      }
    }

    // HTTP 폴백 (+타임아웃/예외 처리)
    try {
      final res = await http
          .post(
        ChatAPI.ask(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': text}),
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final ans = (data['answer'] ?? '(응답이 없습니다)').toString();
        _incoming.add(ChatMessage(role: 'assistant', content: ans));
      } else {
        _incoming.add(ChatMessage(role: 'assistant', content: '서버 오류: ${res.statusCode}'));
      }
    } on TimeoutException {
      _incoming.add(ChatMessage(role: 'assistant', content: '응답이 지연됩니다. 잠시 후 다시 시도해 주세요.'));
    } catch (_) {
      _incoming.add(ChatMessage(role: 'assistant', content: '네트워크 오류가 발생했습니다.'));
    }
  }

  void _disposeSocket() {
    try { _ch?.sink.close(); } catch (_) {}
    _ch = null;
  }

  Future<void> close() async {
    _disposeSocket();
    await _incoming.close();
  }
}
