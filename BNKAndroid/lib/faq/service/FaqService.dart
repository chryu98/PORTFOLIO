// lib/faq/service/FaqService.dart
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
  static final _client = http.Client();

  static Future<bool> ping() async {
    final uri = FAQApi.ping();
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return false;
    final map = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return map['ok'] == true;
  }

  static Future<FaqPageResp> fetch({
    int page = 0,
    int size = 20,
    String query = '',
  }) async {
    final uri = FAQApi.faqList(page: page, size: size, query: query);
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception('FAQ 조회 실패: ${res.statusCode} uri=$uri body=${res.body}');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['content'] as List? ?? const [])
        .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final last = body['last'] == true;
    return FaqPageResp(list, last);
  }

  // 백엔드에 helpful 엔드포인트가 있을 때만 사용
  static Future<void> markHelpful(int faqNo) async {
    final uri = FAQApi.faqHelpful(faqNo);
    final res = await _client.post(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('helpful 실패: ${res.statusCode} uri=$uri body=${res.body}');
    }
  }
}
