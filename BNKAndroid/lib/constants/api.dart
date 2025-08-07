import 'package:http/http.dart' as http;

class API {
  static String? baseUrl;

  // 이 메서드를 앱 시작 시 1회 실행
  static Future<void> initBaseUrl() async {
    const fallbackIp = '192.168.100.106'; // 최후 수동 IP (예: 개발자 1번 PC)
    
    try {
      // fallbackIp를 먼저 사용해서 base-url 얻기
      final response = await http.get(
          Uri.parse('http://$fallbackIp:8090/api/config/base-url'));
      if (response.statusCode == 200) {
        baseUrl = response.body.trim();
        print('[API] baseUrl 세팅됨: $baseUrl');
      } else {
        throw Exception("base-url 응답 실패");
      }
    } catch (e) {
      print('[API] baseUrl 자동 세팅 실패. fallback 사용: $e');
      baseUrl = 'http://$fallbackIp:8090';
    }
  }

  // endpoint getter
  static String get cards => '$baseUrl/api/cards';

  static String cardDetail(int id) => '$baseUrl/api/cards/detail/$id';

  /// 카드 비교용 상세 정보
  static String compareCardDetail(dynamic id) => '$baseUrl/api/cards/$id';

  static String get popularCards => '$baseUrl/api/cards/popular';

  static String searchCards(String keyword, String type, List<String> tags) {
    final params = <String, String>{};
    if (keyword.isNotEmpty) params['q'] = keyword;
    if (type.isNotEmpty && type != '전체') params['type'] = type;
    if (tags.isNotEmpty) params['tags'] = tags.join(',');

    final query = Uri(queryParameters: params).query;
    return '$baseUrl/api/cards/search?$query';
  }
}



//ㅇ이게되네?