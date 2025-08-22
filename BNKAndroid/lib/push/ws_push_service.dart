import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'push_message.dart';

/// 순수 WebSocket 클라이언트 (JSON: {"title","content"})
class WsPushService {
  final Uri wsUri;
  final Map<String, dynamic>? headers; // 인증 필요 시 사용 (서버도 처리 필요)
  WsPushService(this.wsUri, {this.headers});

  WebSocketChannel? _ch;
  StreamSubscription? _sub;

  final _controller = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get stream => _controller.stream;

  Future<void> connect() async {
    await close();
    int retrySec = 2;

    while (_ch == null) {
      try {
        _ch = WebSocketChannel.connect(wsUri/*, headers: headers*/);
        _sub = _ch!.stream.listen((msg) {
          try {
            final data = jsonDecode(msg.toString());
            final title = (data['title'] ?? '').toString();
            final content = (data['content'] ?? '').toString();
            _controller.add(PushMessage(title, content));
          } catch (_) {}
        }, onError: (_) async {
          await _reconnect();
        }, onDone: () async {
          await _reconnect();
        });

        retrySec = 2;
      } catch (_) {
        await Future.delayed(Duration(seconds: retrySec));
        retrySec = ((retrySec * 2).clamp(2, 30) as num).toInt();
      }
    }
  }

  Future<void> _reconnect() async { await close(); }

  Future<void> close() async {
    await _sub?.cancel();
    await _ch?.sink.close();
    _sub = null; _ch = null;
  }

  void dispose() { close(); _controller.close(); }
}
