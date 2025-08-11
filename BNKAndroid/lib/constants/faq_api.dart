// query/page/size만 보냄
class FAQApi {
  static String? baseUrl;

  static Future<void> initBaseUrl() async { /* 지금 쓰던 그대로 */ }

  static String faqList({
    int page = 0,
    int size = 20,
    String query = '',
  }) {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw StateError('FAQApi.baseUrl 비어있음. initBaseUrl() 먼저 호출');
    }
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (query.isNotEmpty) 'query': query,
    };
    final qs = Uri(queryParameters: params).query;
    return '$baseUrl/api/faq?$qs';
  }

  // 도움돼요 기능 안 쓰면 이 메서드는 지워도 됨
  static String faqHelpful(int faqNo) => '$baseUrl/api/faq/$faqNo/helpful';
}
