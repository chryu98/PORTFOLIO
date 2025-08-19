// lib/user/service/card_apply_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';

/// Step7 주소 프리필에 쓰는 간단 모델 (전역에 선언)
class AddressPrefill {
  final String zipCode;
  final String address1;
  final String address2;
  AddressPrefill({
    required this.zipCode,
    required this.address1,
    required this.address2,
  });
}

/// 공통 API 예외
class ApiException implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? body;
  ApiException({required this.message, this.status, this.body});

  @override
  String toString() => 'ApiException(status=$status, message=$message, body=$body)';
}

/// /start 응답 모델
class StartResponse {
  final int applicationNo;
  final bool isCreditCard;
  StartResponse({required this.applicationNo, required this.isCreditCard});

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().trim().toLowerCase();
    if (s == null) return false;
    if (s == 'y' || s == 'yes' || s == 'true' || s == '1') return true;
    if (s == 'n' || s == 'no' || s == 'false' || s == '0') return false;
    return false;
  }

  factory StartResponse.fromJson(Map<String, dynamic> j) => StartResponse(
    applicationNo: (j['applicationNo'] as num).toInt(),
    isCreditCard: _parseBool(j['isCreditCard'] ?? j['credit']),
  );
}

/// /validateInfo 결과
class ValidateResult {
  final bool success;
  final String? message;
  final int? applicationNo;

  ValidateResult({required this.success, this.message, this.applicationNo});

  factory ValidateResult.fromJson(Map<String, dynamic> j) => ValidateResult(
    success: j['success'] == true || (j['success']?.toString().toLowerCase() == 'true'),
    message: j['message']?.toString(),
    applicationNo: (j['applicationNo'] is num) ? (j['applicationNo'] as num).toInt() : null,
  );
}

class CardApplyService {
  // ================== 공통 ==================
  static Future<Map<String, String>> _authHeaders({Map<String, String>? extra}) async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString('jwt_token') ?? p.getString('jwt');
    if (token == null || token.isEmpty) {
      if (kDebugMode) print('[HTTP] no jwt_token in storage');
      throw ApiException(message: '인증 토큰이 없습니다. 다시 로그인 해주세요.', status: 401);
    }
    if (kDebugMode) {
      final head = token.substring(0, token.length.clamp(0, 12));
      print('[HTTP] attach Authorization: Bearer $head...');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final text = utf8.decode(res.bodyBytes);
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) return json;
      throw const FormatException('JSON is not an object');
    } catch (e) {
      throw ApiException(
        message: '응답 파싱 실패',
        status: res.statusCode,
        body: {'raw': res.body},
      );
    }
  }

  static Map<String, dynamic>? _safeDecode(http.Response res) {
    try {
      final text = utf8.decode(res.bodyBytes);
      final json = jsonDecode(text);
      return (json is Map<String, dynamic>) ? json : null;
    } catch (_) {
      return null;
    }
  }

  static void _throwIfHttpError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 401) {
      throw ApiException(
        message: '로그인이 필요합니다.',
        status: 401,
        body: _safeDecode(res),
      );
    }
    final body = _safeDecode(res);
    throw ApiException(
      message: body?['message']?.toString() ?? 'HTTP ${res.statusCode}',
      status: res.statusCode,
      body: body,
    );
  }

  // ================== Step 0/1: 시작/검증 ==================
  /// 발급 시작: POST /card/apply/api/start
  static Future<StartResponse> start({required int cardNo}) async {
    final res = await http.post(
      Uri.parse(API.applyStart),
      headers: await _authHeaders(),
      body: jsonEncode({'cardNo': cardNo}),
    );
    _throwIfHttpError(res);
    final j = _decode(res);

    if (j['success'] == false) {
      throw ApiException(
        message: j['message']?.toString() ?? '발급 시작 실패',
        status: res.statusCode,
        body: j,
      );
    }
    if (j['applicationNo'] is! num) {
      throw ApiException(
        message: 'applicationNo 누락/형식 오류',
        status: res.statusCode,
        body: j,
      );
    }
    return StartResponse.fromJson(j);
  }

  /// 고객정보 검증/임시저장: POST /card/apply/api/validateInfo
  static Future<ValidateResult> validateInfo({
    required int cardNo,
    required String name,
    required String engFirstName,
    required String engLastName,
    required String rrnFront,
    required String rrnBack,
    int? applicationNo,
  }) async {
    final payload = {
      'cardNo': cardNo,
      'name': name,
      'engFirstName': engFirstName,
      'engLastName': engLastName,
      'rrnFront': rrnFront,
      'rrnBack': rrnBack,
      if (applicationNo != null) 'applicationNo': applicationNo,
    };

    final res = await http.post(
      Uri.parse(API.applyValidateInfo),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    _throwIfHttpError(res);
    final Map<String, dynamic> j = _decode(res);
    return ValidateResult.fromJson(j);
  }

  /// 프리필: GET /card/apply/api/prefill
  static Future<Map<String, String>?> prefill() async {
    final res = await http.get(
      Uri.parse(API.applyPrefill),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 204) return null;
    _throwIfHttpError(res);

    final j = _decode(res);
    if (j['success'] != true) return null;

    final p = (j['profile'] ?? {}) as Map<String, dynamic>;
    return {
      'name': (p['name'] ?? '') as String,
      'rrnFront': (p['rrnFront'] ?? '') as String,
    };
  }

  // ================== Step 2/3: 연락처/직업 ==================
  /// 연락처 검증/저장: POST /card/apply/api/validateContact
  static Future<bool> validateContact({
    required int applicationNo,
    required String email,
    required String phone,
  }) async {
    final payload = {
      'applicationNo': applicationNo,
      'email': email,
      'phone': phone,
    };

    final res = await http.post(
      Uri.parse(API.applyValidateContact),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    _throwIfHttpError(res);
    final Map<String, dynamic> j = _decode(res);
    return j['success'] == true;
  }

  /// KYC/직업: POST /card/apply/api/saveJobInfo
  static Future<bool> saveJobInfo({
    required int applicationNo,
    required String job,
    required String purpose,
    required String fundSource,
  }) async {
    final res = await http.post(
      Uri.parse(API.applySaveJobInfo),
      headers: await _authHeaders(),
      body: jsonEncode({
        'applicationNo': applicationNo,
        'job': job,
        'purpose': purpose,
        'fundSource': fundSource,
      }),
    );
    _throwIfHttpError(res);
    final j = _decode(res);
    return j['success'] == true;
  }

  // ================== Step 6: 카드 옵션 ==================
  /// 카드 옵션 저장: POST /api/card/apply/card-options
  static Future<bool> saveCardOptions({
    required int applicationNo,
    required String cardBrand,   // 'VISA' | 'MASTER'
    required bool postpaid,      // 후불교통 Y/N
  }) async {
    final payload = {
      'applicationNo': applicationNo,
      'cardBrand': cardBrand,
      'postpaid': postpaid ? 'Y' : 'N',
    };

    final res = await http.post(
      Uri.parse(API.applyCardOptions),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    _throwIfHttpError(res);
    // 서버가 {"success": true} 형태면 그 값, 아니면 200이면 성공 처리
    final j = _safeDecode(res);
    return j == null ? true : (j['success'] == true);
  }

  // ================== Step 7: 주소 프리필/저장 ==================
  /// 로그인 사용자의 집주소 프리필
  /// (SharedPreferences에 memberNo 또는 loginMemberNo가 저장돼 있다고 가정)
  static Future<AddressPrefill?> fetchHomeAddress() async {
    final res = await http.get(
      Uri.parse(API.applyAddressHome),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 404) return null; // 주소 미등록
    _throwIfHttpError(res);

    final j = _decode(res);
    return AddressPrefill(
      zipCode:  (j['zipCode']  ?? '').toString(),
      address1: (j['address1'] ?? '').toString(),
      address2: (j['address2'] ?? '').toString(),
    );
  }

  /// 주소 저장(임시): POST /api/card/apply/address-save
  static Future<bool> saveAddress({
    required int applicationNo,
    required String zipCode,
    required String address1,      // 기본주소
    required String extraAddress,  // 추가(없으면 '')
    required String address2,      // 상세주소
    required String addressType,   // 'H' or 'W'
  }) async {
    final body = {
      'applicationNo': applicationNo,
      'zipCode': zipCode,
      'address1': address1,
      'extraAddress': extraAddress,
      'address2': address2,
      'addressType': addressType, // 서버에서 'H'/'W'로 정규화
    };

    final res = await http.post(
      Uri.parse(API.applyAddressSave),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    _throwIfHttpError(res);

    // 문자열("주소 저장 완료")일 수도 있으니 안전 처리
    try {
      final j = _decode(res);
      if (j['success'] == true) return true; // JSON 성공 케이스
      return true;                            // 성공이지만 success 필드 없는 JSON
    } catch (_) {
      return true; // 문자열 응답인 경우도 200이면 성공 처리
    }
  }
}
