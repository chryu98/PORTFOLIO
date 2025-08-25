// lib/user/service/account_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bnkandroid/net/api_client.dart';

/// 계좌(Accounts) 관련 API 호출 전용 서비스
/// - ApiClient.getAuth/postAuth: jwt_token 기반 인증 헤더 자동 부착
/// - UTF-8 안전 디코딩
/// - 에러 발생 시 status/body 포함 반환
class AccountService {
  // 공통 디코더
  static Map<String, dynamic> _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    try {
      final obj = jsonDecode(text);
      if (obj is Map<String, dynamic>) return obj;
      return {'success': res.statusCode < 400, 'status': res.statusCode, 'raw': obj};
    } catch (_) {
      return {'success': res.statusCode < 400, 'status': res.statusCode, 'body': text};
    }
  }

  /// 현재 로그인 사용자의 활성 계좌 목록/상태
  static Future<Map<String, dynamic>> state() async {
    final res = await ApiClient.getAuth('/card/apply/api/accounts/state');
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][GET  /state] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }

  /// (옵션) 이미 있으면 생성 안 함
  static Future<Map<String, dynamic>> createIfNone({
    int? cardNo,
    String? accountPw,
  }) async {
    final res = await ApiClient.postAuth(
      '/card/apply/api/accounts/create-if-none',
      {
        if (cardNo != null) 'cardNo': cardNo,
        if (accountPw != null && accountPw.isNotEmpty) 'accountPw': accountPw,
      },
    );
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][POST /create-if-none] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }

  /// 무조건 새 계좌 생성(비번은 추후 설정)
  static Future<Map<String, dynamic>> autoCreate({int? cardNo}) async {
    final res = await ApiClient.postAuth(
      '/card/apply/api/accounts/auto-create',
      {if (cardNo != null) 'cardNo': cardNo},
    );
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][POST /auto-create] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }

  /// 새/기존 계좌 비밀번호 설정(숫자 4~6, pw1==pw2)
  static Future<Map<String, dynamic>> setPassword({
    required int acNo,
    required String pw1,
    required String pw2,
  }) async {
    final res = await ApiClient.postAuth(
      '/card/apply/api/accounts/$acNo/set-password',
      {'pw1': pw1, 'pw2': pw2},
    );
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][POST /$acNo/set-password] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }

  /// 기존 계좌 사용: 비번 검증 + 서버 세션 선택
  static Future<Map<String, dynamic>> verifyAndSelect({
    required int acNo,
    required String password,
  }) async {
    final res = await ApiClient.postAuth(
      '/card/apply/api/accounts/$acNo/verify-and-select',
      {'password': password},
    );
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][POST /$acNo/verify-and-select] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }

  /// (신규) 비번 없이 단순 세션 선택 (신규 계좌 비번 설정 직후 사용)
  static Future<Map<String, dynamic>> selectAccount({required int acNo}) async {
    final res = await ApiClient.postAuth(
      '/card/apply/api/accounts/select',
      {'acNo': acNo},
    );
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][POST /select] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }

  /// 계좌 해지
  static Future<Map<String, dynamic>> close({required int acNo}) async {
    final res = await ApiClient.postAuth('/card/apply/api/accounts/$acNo/close', {});
    if (res.statusCode >= 400) {
      // ignore: avoid_print
      print('[AccountService][POST /$acNo/close] ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
    return _decode(res);
  }
}
