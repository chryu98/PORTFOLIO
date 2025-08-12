// lib/constants/faq_api.dart
class FAQApi {
  static late String baseUrl;     // 예: http://192.168.0.5:8090
  static String pathPrefix = '';  // 예: '', '/api'

  /// 반드시 앱 시작 시 한 번 호출해서 LAN IP로 고정
  static void useLan({required String ip, int port = 8090, String scheme = 'http'}) {
    baseUrl = '$scheme://$ip:$port';
  }

  /// 서버의 context-path 지정 ('', '/', '/api' 중 하나)
  static void setPathPrefix(String prefix) {
    if (prefix.isEmpty || prefix == '/') {
      pathPrefix = '';
    } else {
      pathPrefix = prefix.startsWith('/') ? prefix : '/$prefix';
    }
  }

  static Uri _uri(String path, {Map<String, String>? params}) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final pfx  = pathPrefix; // '', '/api'
    final p    = path.startsWith('/') ? path : '/$path';
    final url  = '$base$pfx$p';
    return Uri.parse(url).replace(queryParameters: params);
  }

  // Endpoints
  static Uri faqList({int page = 0, int size = 20, String query = ''}) =>
      _uri('/faq', params: {'page':'$page','size':'$size', if (query.isNotEmpty) 'query':query});

  static Uri ping() => _uri('/faq/ping');

  static Uri faqHelpful(int faqNo) => _uri('/faq/$faqNo/helpful');
}
