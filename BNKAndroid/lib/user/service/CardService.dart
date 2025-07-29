import 'dart:convert';
import '../model/CardModel.dart';
import 'package:http/http.dart' as http;

class CardService {
  static Future<List<CardModel>> fetchCards() async {
    final response = await http.get(Uri.parse('http://192.168.100.106:8090/api/cards'));

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes); // ← 여기가 핵심
      final List jsonData = json.decode(decoded);
      return jsonData.map((e) => CardModel.fromJson(e)).toList();
    } else {
      throw Exception('카드 목록 로딩 실패');
    }
  }
}
