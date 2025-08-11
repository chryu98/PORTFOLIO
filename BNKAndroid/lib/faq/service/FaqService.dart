import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/faq_api.dart';
import '../model/FaqModel.dart';

class FaqPageResp {
  final List<FaqModel> content;
  final bool last;
  FaqPageResp(this.content, this.last);
}

class FaqService {
  static Future<FaqPageResp> fetch({
    int page = 0,
    int size = 20,
    String query = '',
  }) async {
    final url = FAQApi.faqList(page: page, size: size, query: query);
    print('[FaqService] GET $url');
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('FAQ 조회 실패: ${res.statusCode} url=$url body=${res.body}');
    }
    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['content'] as List? ?? [])
        .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final last = body['last'] == true;
    return FaqPageResp(list, last);
  }

  // 도움돼요 안 쓰면 전부 삭제해도 됨
  static Future<void> markHelpful(int faqNo) async {}
}
