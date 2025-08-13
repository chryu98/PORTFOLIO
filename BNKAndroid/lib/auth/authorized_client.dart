import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_store.dart';

class AuthorizedClient {
  static Future<http.Response> get(String url) async {
    final token = await TokenStore.I.load();
    if (token == null) throw Exception('저장된 토큰이 없습니다.');
    return http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final token = await TokenStore.I.load();
    if (token == null) throw Exception('저장된 토큰이 없습니다.');
    return http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final token = await TokenStore.I.load();
    if (token == null) throw Exception('저장된 토큰이 없습니다.');
    return http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String url) async {
    final token = await TokenStore.I.load();
    if (token == null) throw Exception('저장된 토큰이 없습니다.');
    return http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
