import 'package:http/http.dart' as http;

class API {
  static String? baseUrl;

  static Future<void> initBaseUrl() async {
    const fallbackIp = '192.168.0.5';
    try {
      final r = await http.get(Uri.parse('http://$fallbackIp:8090/api/config/base-url'));
      if (r.statusCode == 200) {
        baseUrl = r.body.trim(); // 예: http://192.168.100.106:8090[/컨텍스트]
        print('[API] baseUrl 세팅됨: $baseUrl');
      } else {
        throw Exception("base-url 응답 실패");
      }
    } catch (e) {
      print('[API] baseUrl 자동 세팅 실패. fallback 사용: $e');
      baseUrl = 'http://$fallbackIp:8090';
    }
  }

  // --- 공용 path join (슬래시 중복 방지)
  static String _j(String p) {
    final b = baseUrl ?? '';
    return b.endsWith('/') ? '$b${p.startsWith('/') ? p.substring(1) : p}'
        : '$b${p.startsWith('/') ? p : '/$p'}';
  }

  // 기존 카드 API
  static String get cards => _j('/api/cards');
  static String cardDetail(int id) => _j('/api/cards/detail/$id');
  static String compareCardDetail(dynamic id) => _j('/api/cards/$id');
  static String get popularCards => _j('/api/cards/popular');
  static String searchCards(String keyword, String type, List<String> tags) {
    final params = <String, String>{};
    if (keyword.isNotEmpty) params['q'] = keyword;
    if (type.isNotEmpty && type != '전체') params['type'] = type;
    if (tags.isNotEmpty) params['tags'] = tags.join(',');
    final q = Uri(queryParameters: params).query;
    return _j('/api/cards/search?$q');
  }

  // 🔴 발급/검증 엔드포인트 추가
  static String get applyStart        => _j('/card/apply/api/start');
  static String get applyValidateInfo => _j('/card/apply/api/validateInfo');
// (선택) 프리필: static String applyPrefill() => _j('/card/apply/api/prefill');
}
