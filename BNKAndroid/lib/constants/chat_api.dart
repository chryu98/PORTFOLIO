// lib/constants/chat_api.dart
class ChatAPI {
  static late String baseHttp;
  static String? baseWs;
  static late String askPath;
  static String? wsPath;

  // FastAPI로 직접 붙을 때 (기본)
  // 예: http://192.168.0.5:8000  /ask, /ws
  static void useFastAPI({required String ip, int port = 8000, bool https = false}) {
    final scheme = https ? 'https' : 'http';
    final wss    = https ? 'wss'   : 'ws';
    baseHttp = '$scheme://$ip:$port';
    baseWs   = '$wss://$ip:$port';
    askPath  = '/ask';
    wsPath   = '/ws';
  }

  // 스프링 프록시로 붙을 때
  // 예: http://192.168.0.5:8090  /api/chat/ask  (ws 프록시는 선택)
  static void useSpringProxy({required String ip, int port = 8090, bool https = false, bool withWs = false}) {
    final scheme = https ? 'https' : 'http';
    final wss    = https ? 'wss'   : 'ws';
    baseHttp = '$scheme://$ip:$port';
    baseWs   = withWs ? '$wss://$ip:$port' : null;
    askPath  = '/api/chat/ask';
    wsPath   = withWs ? '/api/chat/ws' : null;
  }

  static Uri ask() => Uri.parse('$baseHttp$askPath');

  static Uri ws() {
    if (baseWs == null || wsPath == null) {
      throw StateError('WebSocket endpoint is not configured');
    }
    return Uri.parse('${baseWs!}${wsPath!}');
  }
}
