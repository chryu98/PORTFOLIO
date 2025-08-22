import 'dart:convert';
import '../../constants/api.dart';
import '../model/CardModel.dart';
import 'package:http/http.dart' as http;


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

  /// 인기카드 Top3 (플러터 전용 API)
  static Future<List<CardModel>> fetchPopularTop3() async {
    final url = Uri.parse('${API.baseUrl}/cards/top3');
    final r = await http.get(url);

    if (r.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(utf8.decode(r.bodyBytes));
      return jsonList.map((e) => CardModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load popular top3 cards');
    }
  }

  //검색창 기능
  static Future<List<CardModel>> searchCards({
    String keyword = '',
    String type = '',
    List<String> tags = const [],
  }) async {
    final url = API.searchCards(keyword, type, tags);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => CardModel.fromJson(e)).toList();
    } else {
      throw Exception('검색 실패: ${response.statusCode}');
    }
  }

  //모달 비교창 & 카드디테일 로딩
  static Future<CardModel> fetchCompareCardDetail(String cardId) async {
    final url = API.compareCardDetail(cardId);
    print('📡 [API 호출] $url');

    final response = await http.get(Uri.parse(url));
    print('📥 응답 코드: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      print('📦 응답 데이터: $body');
      return CardModel.fromJson(json.decode(body));
    } else {
      print('❌ 실패 응답: ${response.body}');
      throw Exception('카드 상세 조회 실패 (${response.statusCode})');
    }
  }






}
