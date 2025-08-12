import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api.dart';
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
}

/// /validateInfo 성공/실패 결과
class ValidateResult {
  final bool success;
  final String? message;
  final int? applicationNo; // 백엔드에서 넣어주면 사용

  ValidateResult({required this.success, this.message, this.applicationNo});
}

class CardApplyService {
  /// 발급 시작: /card/apply/api/start (POST)
  static Future<StartResponse> start({required int cardNo}) async {
    final url = API.applyStart; // 게터라면 괄호 X
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cardNo': cardNo}),
    );

    final Map<String, dynamic> j = _decode(res);
    _throwIfHttpError(res, j);

    if (j['success'] != true) {
      throw ApiException(
        message: j['message']?.toString() ?? '시작 실패',
        status: res.statusCode,
        body: j,
      );
    }

    final appNo = j['applicationNo'];
    final isCredit = (j['isCreditCard']?.toString() ?? 'N') == 'Y';

    if (appNo is! int) {
      throw ApiException(message: 'applicationNo 누락/형식 오류', status: res.statusCode, body: j);
    }

    return StartResponse(applicationNo: appNo, isCreditCard: isCredit);
  }

  /// 고객정보 검증/임시저장: /card/apply/api/validateInfo (POST)
  static Future<ValidateResult> validateInfo({
    required int cardNo,
    required String name,
    required String engFirstName,
    required String engLastName,
    required String rrnFront,
    required String rrnBack,
    int? applicationNo, // (선택) 중복 생성 방지 시 사용
  }) async {
    final url = API.applyValidateInfo; // 게터라면 괄호 X
    final payload = {
      'cardNo': cardNo,
      'name': name,
      'engFirstName': engFirstName,
      'engLastName': engLastName,
      'rrnFront': rrnFront,
      'rrnBack': rrnBack,
      if (applicationNo != null) 'applicationNo': applicationNo,
    };

    // 디버그 로그
    // ignore: avoid_print
    print('POST $url\nbody=$payload');

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> j = _decode(res);

    if (res.statusCode == 200) {
      return ValidateResult(
        success: j['success'] == true,
        message: j['message']?.toString(),
        applicationNo: (j['applicationNo'] is int) ? j['applicationNo'] as int : null,
      );
    }

    // 4xx/5xx는 예외
    throw ApiException(
      message: j['message']?.toString() ?? '검증/저장 실패',
      status: res.statusCode,
      body: j,
    );
  }

  /// (선택) 프리필: /card/apply/api/prefill (GET)
  static Future<Map<String, dynamic>?> prefill() async {
    // api.dart에 applyPrefill 게터를 만들었다면 아래 주석 풀고 사용:
    // final url = API.applyPrefill;
    // final res = await http.get(Uri.parse(url));
    // if (res.statusCode != 200) return null;
    // return _decode(res);

    return null; // 필요 없으면 제거
  }

  // ----------------- 내부 헬퍼 -----------------

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

  static void _throwIfHttpError(http.Response res, Map<String, dynamic> body) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(
      message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      status: res.statusCode,
      body: body,
    );
  }
}
