// lib/constants/api.dart
import 'package:http/http.dart' as http;

class API {
  static String? baseUrl;

  /// 앱 실행 시 호출해 baseUrl 자동 세팅
  static Future<void> initBaseUrl() async {
    const fallbackIp = '192.168.0.229';
    try {
      final r = await http.get(Uri.parse('http://$fallbackIp:8090/api/config/base-url'));
      if (r.statusCode == 200) {
        baseUrl = r.body.trim();
        print('[API] baseUrl 세팅됨: $baseUrl');
      } else {
        throw Exception("base-url 응답 실패");
      }
    } catch (e) {
      print('[API] baseUrl 자동 세팅 실패. fallback 사용: $e');
      baseUrl = 'http://$fallbackIp:8090';
    }
  }

  /// 내부 URL 조합기
  static String _j(String path) {
    if (baseUrl == null) {
      print('[API] 경고: baseUrl이 설정되지 않았습니다.');
    }
    final b = baseUrl ?? '';
    return b.endsWith('/')
        ? '$b${path.startsWith('/') ? path.substring(1) : path}'
        : '$b${path.startsWith('/') ? path : '/$path'}';
  }

  // ===== 카드 API =====
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

  // ===== 발급 API =====
  static String get applyStart           => _j('/card/apply/api/start');
  static String get applyValidateInfo    => _j('/card/apply/api/validateInfo');
  static String get applyPrefill         => _j('/card/apply/api/prefill');
  static String get applyValidateContact => _j('/card/apply/api/validateContact');

  // ===== JWT API =====
  static String get jwtLogin  => _j('/jwt/api/login');
  static String get jwtLogout => _j('/jwt/api/logout'); // 선택
  static String get jwtRefresh => _j('/jwt/api/refresh'); // 선택
}
