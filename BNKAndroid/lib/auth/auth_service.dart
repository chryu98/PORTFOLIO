// lib/auth/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api.dart';
import 'token_store.dart';

class AuthService {
  /// 로그인: 서버 응답의 토큰을 최대한 유연하게 파싱해 저장
  /// - JSON body: accessToken / token / jwt
  /// - Header: Authorization: Bearer xxx
  /// - (옵션) Set-Cookie: JSESSIONID=...
  static Future<void> login(String username, String password) async {
    final uri = Uri.parse(API.jwtLogin); // 예: http://HOST:PORT/jwt/api/login
    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('로그인 실패: HTTP ${res.statusCode}');
    }

    // 1) Body에서 토큰 찾기
    String? token;
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map<String, dynamic>) {
        token = (body['accessToken'] ?? body['token'] ?? body['jwt'])?.toString();
      }
    } catch (_) {
      // body가 JSON이 아닐 수 있음 → 무시하고 헤더에서 찾기
    }

    // 2) Header에서 토큰 찾기 (Authorization: Bearer xxx)
    token ??= _parseBearerFromHeader(res.headers['authorization']) ??
        _parseBearerFromHeader(res.headers['Authorization']);

    if (token == null || token.isEmpty) {
      throw Exception('로그인 응답에 토큰이 없습니다.');
    }

    // 3) 토큰 저장 (TokenStore + SharedPreferences 동시 저장)
    await TokenStore.I.save(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ACCESS_TOKEN', token);

    // 4) (옵션) 세션 쿠키 저장 (필요 시)
    final setCookie = res.headers['set-cookie'];
    if (setCookie != null) {
      final jsid = RegExp(r'JSESSIONID=([^;]+)').firstMatch(setCookie)?.group(1);
      if (jsid != null && jsid.isNotEmpty) {
        await prefs.setString('JSESSIONID', jsid);
      }
    }

    // 디버그 로그 (원하면 주석)
    // ignore: avoid_print
    print('[AuthService] login ok, tokenLen=${token.length} '
        'hasJSESSION=${prefs.getString('JSESSIONID') != null}');
  }

  static String? _parseBearerFromHeader(String? header) {
    if (header == null) return null;
    final h = header.trim();
    if (h.toLowerCase().startsWith('bearer ')) {
      return h.substring(7).trim();
    }
    return null;
  }

  /// 로그아웃: 토큰/세션 모두 클리어
  static Future<void> logout() async {
    await TokenStore.I.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ACCESS_TOKEN');
    await prefs.remove('JSESSIONID');
    // ignore: avoid_print
    print('[AuthService] logout done');
  }
}
