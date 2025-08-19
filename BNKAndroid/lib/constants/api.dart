// lib/constants/api.dart
import 'package:http/http.dart' as http;

class API {
  static String? baseUrl;

  /// 앱 시작 시 1회 호출해서 baseUrl 자동 세팅
  static Future<void> initBaseUrl() async {
    const fallbackIp = '192.168.100.106'; // 각자 로컬/사내망 IP면 여기만 개인별로 바꿔도 동작
    try {
      final r = await http.get(
        Uri.parse('http://$fallbackIp:8090/api/config/base-url'),
      );
      if (r.statusCode == 200) {
        baseUrl = r.body.trim();
        // ignore: avoid_print
        print('[API] baseUrl 세팅됨: $baseUrl');
      } else {
        throw Exception('base-url 응답 실패(${r.statusCode})');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[API] baseUrl 자동 세팅 실패. fallback 사용: $e');
      baseUrl = 'http://$fallbackIp:8090';
    }
  }

  /// 내부 URL 조합기 (네가 쓰던 _j 그대로 유지)
  static String _j(String path) {
    if (baseUrl == null) {
      // ignore: avoid_print
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

  // ===== 발급(Apply) API =====
  static String get applyStart           => _j('/card/apply/api/start');
  static String get applyValidateInfo    => _j('/card/apply/api/validateInfo');
  static String get applyPrefill         => _j('/card/apply/api/prefill');
  static String get applyValidateContact => _j('/card/apply/api/validateContact');
  static String get applySaveJobInfo     => _j('/card/apply/api/saveJobInfo');

  // ▶ 페이지 6(카드 옵션) / 7(주소)에서 쓰는 신규 추가 엔드포인트들
  static String get applyCardOptions     => _j('/api/card/apply/card-options');
  static String get applyAddressHome     => _j('/api/card/apply/address-home');
  static String get applyAddressSave     => _j('/api/card/apply/address-save');

  // ===== JWT =====
  static String get jwtLogin   => _j('/jwt/api/login');
  static String get jwtLogout  => _j('/jwt/api/logout');
  static String get jwtRefresh => _j('/jwt/api/refresh');
}
