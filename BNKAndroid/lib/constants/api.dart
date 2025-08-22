// lib/constants/api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 공용 API 유틸 (JWT/세션 쿠키 자동부착 + 401 자동갱신 지원)
class API {
  static String? baseUrl;
  static final http.Client _client = http.Client();

  static const String _fallbackHost = '192.168.100.106';

  static const int _configPort = 8090; // 설정 서버
  static const int _apiPort    = 8090; // 실제 스프링 API

  // ── 키: JWT / 리프레시 / 쿠키 ────────────────────────────────────────────
  static const _kAccess = 'accessToken';      // 표준 키
  static const _kRefresh = 'refreshToken';    // 표준 키
  static const _kCookie  = 'JSESSIONID.raw';  // "JSESSIONID=...; Path=/; ..." 전체 저장

  /// 앱 시작 시 1회 호출
  static Future<void> initBaseUrl() async {
    const fallbackIp = '192.168.0.224'; // 각자 로컬/사내망 IP면 여기만 개인별로 바꿔도 동작
    try {
      final cfg = await _client.get(
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

  // ────────────────────────────────────────────────────────────────────────
  // 저장/로드 유틸 (기존 키들까지 호환: accessToken / jwt_token / token)
  // ────────────────────────────────────────────────────────────────────────
  static Future<void> saveJwt({required String access, String? refresh}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    if (refresh != null) await sp.setString(_kRefresh, refresh);
  }

  static Future<void> saveCookie(String fullCookie) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCookie, fullCookie);
  }

  static Future<String?> _getAccess() async {
    final sp = await SharedPreferences.getInstance();
    // 기존 키 호환
    return sp.getString(_kAccess)
        ?? sp.getString('jwt_token')
        ?? sp.getString('token');
  }

  static Future<String?> _getRefresh() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRefresh);
  }

  static Future<String?> _getCookie() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kCookie);
  }

  static Future<void> clearAuth() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
    await sp.remove(_kRefresh);
    await sp.remove(_kCookie);
    await sp.remove('jwt_token');
    await sp.remove('token');
  }

  // ── 토큰/쿠키 헤더 생성기 ────────────────────────────────────────────────
  static Future<Map<String, String>> authHeader() async {
    final headers = <String, String>{};

    final access = await _getAccess();
    if (access != null && access.isNotEmpty) {
      final raw = access.startsWith('Bearer ') ? access.substring(7) : access; // Double Bearer 방지
      headers['Authorization'] = 'Bearer $raw';
    }

    final cookie = await _getCookie();
    if (cookie != null && cookie.isNotEmpty) {
      // 여러 세트가 올 수 있어 첫 세트 우선 사용
      headers['Cookie'] = cookie.split(',').first;
    }
    return headers;
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

  // ────────────────────────────────────────────────────────────────────────
  // 공통 JSON 요청 헬퍼 (자동 인증 + 401 리프레시 1회 재시도)
  // ────────────────────────────────────────────────────────────────────────
  static Future<dynamic> getJ(
      String pathOrUrl, {
        Map<String, dynamic>? params,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(_resolve(pathOrUrl)).replace(
      queryParameters: params?.map((k, v) => MapEntry(k, '$v')),
    );
    return _request('GET', uri, headers: headers);
  }

  static Future<dynamic> postJ(
      String pathOrUrl, {
        Object? body,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(_resolve(pathOrUrl));
    return _request('POST', uri, body: body, headers: headers);
  }

  static Future<dynamic> putJ(
      String pathOrUrl, {
        Object? body,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(_resolve(pathOrUrl));
    return _request('PUT', uri, body: body, headers: headers);
  }

  static Future<dynamic> deleteJ(
      String pathOrUrl, {
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse(_resolve(pathOrUrl));
    return _request('DELETE', uri, headers: headers);
  }

  static Future<dynamic> _request(
      String method,
      Uri uri, {
        Object? body,
        Map<String, String>? headers,
        bool retry = false, // ⬅︎ 401 재시도 플래그
      }) async {
    final auth = await authHeader();
    final merged = {
      'Content-Type': 'application/json; charset=utf-8',
      ...auth,
      ...?headers,
    };

    http.Response res;
    switch (method) {
      case 'GET':
        res = await _client.get(uri, headers: merged);
        break;
      case 'POST':
        res = await _client.post(uri, headers: merged, body: body);
        break;
      case 'PUT':
        res = await _client.put(uri, headers: merged, body: body);
        break;
      case 'DELETE':
        res = await _client.delete(uri, headers: merged);
        break;
      default:
        throw ApiException(statusCode: -1, raw: 'Unsupported method: $method');
    }

    // 세션 방식일 경우 Set-Cookie가 오면 저장
    final setCookie = res.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      await saveCookie(setCookie.split(',').first);
    }

    if (res.statusCode == 401 && !retry) {
      final ok = await _tryRefreshToken();
      if (ok) {
        return _request(
          method,
          uri,
          body: body,
          headers: headers,
          retry: true,
        );
      }
      await clearAuth();
      throw ApiException(statusCode: 401, raw: '로그인이 필요합니다 (401)');
    }

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

  // ── 401 시 JWT 재발급 시도 ───────────────────────────────────────────────
  static Future<bool> _tryRefreshToken() async {
    final refresh = await _getRefresh();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final uri = Uri.parse(_resolve(jwtRefresh));
      final resp = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final newAccess = (data['accessToken'] ?? data['access']) as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await saveJwt(access: newAccess, refresh: refresh);
          return true;
        }
      }
    } catch (_) {
      // ignore
    }
    return false;
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
  static String termsPdf(int pdfNo)      => _j('/api/card/apply/pdf/$pdfNo');

  // 페이지 8(카드 비번)
  static String pinSave(int cardNo)      => _j('/card/apply/api/card-password/$cardNo/pin');

  // 승격(옵션 A: 클라에서 호출)
  static String promote(int appNo)       => _j('/api/card/apply/promote/$appNo');


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

  /// 커스텀 메시지 추출용 게터
  String? get message {
    if (raw != null && raw!.isNotEmpty) return raw;
    if (body is Map && (body as Map)['message'] != null) {
      return (body as Map)['message'].toString();
    }
    if (body is String) return body as String;
    return null;
  }

  @override
  String toString() =>
      'ApiException($statusCode) ${message ?? raw ?? body ?? ''}';
}
