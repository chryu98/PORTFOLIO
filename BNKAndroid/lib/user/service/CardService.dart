import 'dart:convert';
import '../model/CardModel.dart';
import 'package:http/http.dart' as http;
import 'package:bnkandroid/constants/api.dart'; // 또는 상대경로로 수정

class CardService {
  /// 전체 카드 목록 조회
  static Future<List<CardModel>> fetchCards() async {
    if (API.baseUrl == null) {
      throw Exception("baseUrl이 초기화되지 않았습니다.");
    }

    final response = await http.get(Uri.parse(API.cards));

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List jsonData = json.decode(decoded);
      return jsonData.map((e) => CardModel.fromJson(e)).toList();
    } else {
      throw Exception('카드 목록 로딩 실패');
    }
  }

  /// 인기 카드 (슬라이더용) 목록 조회
  static Future<List<CardModel>> fetchPopularCards() async {
    if (API.baseUrl == null) {
      throw Exception("baseUrl이 초기화되지 않았습니다.");
    }

    final response = await http.get(Uri.parse(API.popularCards));

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List jsonList = jsonDecode(decoded);
      return jsonList.map((e) => CardModel.fromJson(e)).toList();
    } else {
      throw Exception('인기 카드 로딩 실패');
    }
  }
}
