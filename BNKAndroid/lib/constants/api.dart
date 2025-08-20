// lib/constants/api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 공용 API 유틸
class API {
  static String? baseUrl;

  // 사내/로컬 환경 기본값
  static const String _fallbackHost = '192.168.100.106';
  static const int _configPort = 8090; // 설정 서버
  static const int _apiPort    = 8080; // 실제 스프링 API

  /// 앱 시작 시 1회 호출
  static Future<void> initBaseUrl() async {
    const fallbackIp = '192.168.0.5'; // 각자 로컬/사내망 IP면 여기만 개인별로 바꿔도 동작
    try {
      final cfg = await http.get(
        Uri.parse('http://$_fallbackHost:$_configPort/api/config/base-url'),
      );
      if (cfg.statusCode == 200 && cfg.body.trim().isNotEmpty) {
        baseUrl = cfg.body.trim();
        // ignore: avoid_print
        print('[API] baseUrl from config: $baseUrl');
        return;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[API] config server not reachable: $e');
    }

    if (kIsWeb) {
      baseUrl = 'http://localhost:$_apiPort';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          baseUrl = 'http://10.0.2.2:$_apiPort';
          break;
        case TargetPlatform.iOS:
          baseUrl = 'http://127.0.0.1:$_apiPort';
          break;
        default:
          baseUrl = 'http://localhost:$_apiPort';
          break;
      }
    }
    // ignore: avoid_print
    print('[API] baseUrl fallback: $baseUrl');
  }

  // ── 토큰 헤더 (1~7단계 동일) ────────────────────────────────────────────────
  static Future<Map<String, String>> authHeader() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('accessToken')
        ?? prefs.getString('jwt_token')
        ?? prefs.getString('token');

    if (token == null || token.isEmpty) return {};

    final raw = token.startsWith('Bearer ') ? token.substring(7) : token; // Double Bearer 방지
    return {'Authorization': 'Bearer $raw'};
  }

  // ── 내부 URL 조합기 ───────────────────────────────────────────────────────
  static String _j(String path) {
    final b = (baseUrl ?? '').trim();
    if (b.isEmpty) {
      // ignore: avoid_print
      print('[API] 경고: baseUrl이 아직 초기화되지 않았습니다. initBaseUrl() 호출 필요');
    }
    return b.endsWith('/')
        ? '$b${path.startsWith('/') ? path.substring(1) : path}'
        : '$b${path.startsWith('/') ? path : '/$path'}';
  }

  /// ✅ 절대 URL은 그대로, 상대 경로만 baseUrl을 붙임
  static String _resolve(String pathOrUrl) {
    final s = pathOrUrl.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    return _j(s);
  }

  // ── 공통 JSON 요청 헬퍼 ───────────────────────────────────────────────────
  static Future<dynamic> getJ(
      String pathOrUrl, {
        Map<String, dynamic>? params,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(_resolve(pathOrUrl)).replace(
      queryParameters: params?.map((k, v) => MapEntry(k, '$v')),
    );
    final res = await http.get(uri, headers: headers);
    return _handle(res);
  }

  static Future<dynamic> postJ(
      String pathOrUrl, {
        Object? body,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(_resolve(pathOrUrl));
    final merged = {'Content-Type': 'application/json', ...?headers};
    final res = await http.post(uri, headers: merged, body: body);
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    dynamic jsonBody;
    try {
      jsonBody = text.isNotEmpty ? jsonDecode(text) : null;
    } catch (_) {
      jsonBody = text; // JSON이 아니면 원문
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return jsonBody;
    throw ApiException(statusCode: res.statusCode, body: jsonBody, raw: text);
  }

  // ── 엔드포인트 빌더 ───────────────────────────────────────────────────────
  // 카드
  static String get cards => _j('/api/cards');
  static String cardDetail(int id) => _j('/api/cards/detail/$id');
  static String compareCardDetail(dynamic id) => _j('/api/cards/$id');
  static String get popularCards => _j('/api/cards/popular');
  static String searchCards(String keyword, String type, List<String> tags) {
    final params = <String, String>{};
    if (keyword.isNotEmpty) params['q'] = keyword;
    if (type.isNotEmpty && type != '전체') params['type'] = type;
    if (tags.isNotEmpty) params['tags'] = tags.join(',');
    final q = Uri(queryParameters: params).query;
    return _j('/api/cards/search?$q');
  }

  // 발급 공정(1~7)
  static String get applyStart           => _j('/card/apply/api/start');
  static String get applyValidateInfo    => _j('/card/apply/api/validateInfo');
  static String get applyPrefill         => _j('/card/apply/api/prefill');
  static String get applyValidateContact => _j('/card/apply/api/validateContact');
  static String get applySaveJobInfo     => _j('/card/apply/api/saveJobInfo');

  // 페이지 6/7
  static String get applyCardOptions     => _j('/api/card/apply/card-options');
  static String get applyAddressHome     => _j('/api/card/apply/address-home');
  static String get applyAddressSave     => _j('/api/card/apply/address-save');

  // 페이지 0(약관)
  static String get termsListByCard      => _j('/api/card/apply/card-terms');     // GET ?cardNo=
  static String get termsAgree           => _j('/api/card/apply/terms-agree');    // POST
  static String get customerInfo         => _j('/api/card/apply/customer-info');  // GET ?cardNo=

  // JWT
  static String get jwtLogin   => _j('/jwt/api/login');
  static String get jwtLogout  => _j('/jwt/api/logout');
  static String get jwtRefresh => _j('/jwt/api/refresh');
}

/// 통일된 예외 타입
class ApiException implements Exception {
  final int statusCode;
  final dynamic body;
  final String? raw;
  ApiException({required this.statusCode, this.body, this.raw});
  @override
  String toString() => 'ApiException($statusCode) ${raw ?? body ?? ''}';
}
