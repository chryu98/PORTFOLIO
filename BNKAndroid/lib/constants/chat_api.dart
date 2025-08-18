class ChatAPI {
  static String? baseHttp;
  static String? baseWs;
  static String askPath = "/ask";   // 기본값: FastAPI
  static String wsPath  = "/ws";    // 기본값: FastAPI

  // 생성자 역할처럼 앱 시작 시 자동으로 FastAPI 모드 세팅
  static void _init() {
    useFastAPI(ip: "192.168.0.5", port: 8000);  // ✅ 기본을 FastAPI로
  }

  /// FastAPI 서버 직접 연결
  static void useFastAPI({required String ip, int port = 8000, bool https = false}) {
    final scheme = https ? 'https' : 'http';
    final wss    = https ? 'wss'   : 'ws';
    baseHttp = '$scheme://$ip:$port';
    baseWs   = '$wss://$ip:$port';
    askPath  = "/ask";
    wsPath   = "/ws";
    print("[ChatAPI] FastAPI 연결: $baseHttp$askPath");
  }

  /// Spring Proxy 경유
  static void useSpringProxy({
    required String ip,
    int port = 8090,
    bool https = false,
    String ask = "/api/chat/ask",
    String ws  = "/ws-stomp/websocket",
  }) {
    final scheme = https ? 'https' : 'http';
    final wss    = https ? 'wss'   : 'ws';
    baseHttp = '$scheme://$ip:$port';
    baseWs   = '$wss://$ip:$port';
    askPath  = ask;
    wsPath   = ws;
    print("[ChatAPI] Spring Proxy 연결: $baseHttp$askPath");
  }

  static Uri ask() {
    if (baseHttp == null) {
      _init(); // ⚡ 자동 초기화 (FastAPI)
    }
    return Uri.parse('$baseHttp$askPath');
  }

  static Uri ws() {
    if (baseWs == null) {
      _init(); // ⚡ 자동 초기화 (FastAPI)
    }
    return Uri.parse('${baseWs!}$wsPath');
  }
}
