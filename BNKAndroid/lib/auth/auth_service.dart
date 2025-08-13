// lib/auth/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import 'token_store.dart';

class AuthService {
  static Future<void> login(String username, String password) async {
    final res = await http.post(
      Uri.parse(API.jwtLogin), // "/jwt/api/login"
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception('로그인 실패: ${res.statusCode}');
    }
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final token = j['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('응답에 token 없음');
    }
    await TokenStore.I.save(token);
  }

  static Future<void> logout() => TokenStore.I.clear();
}
