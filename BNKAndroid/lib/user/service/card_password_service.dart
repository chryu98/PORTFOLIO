// lib/user/service/card_password_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bnkandroid/constants/api.dart' as API;
import '../model/pin_models.dart';


class ApiException implements Exception {
  final int statusCode;
  final dynamic body;
  final String? raw;
  ApiException({required this.statusCode, this.body, this.raw});

  int get status => statusCode; // 예전 코드 호환용
  String? get message {
    if (raw != null && raw!.isNotEmpty) return raw;
    if (body is Map && (body as Map)['message'] != null) {
      return (body as Map)['message'].toString();
    }
    if (body is String) return body as String;
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode) ${message ?? raw ?? body ?? ''}';
}

class CardPasswordService {
  /// 서버에 PIN 저장(덮어쓰기)
  static Future<PinSaveResult> savePin({
    required int cardNo,
    required String pin1,
    required String pin2,
  }) async {
    // 간단한 클라이언트측 검증(서버도 다시 검증함)
    if (pin1 != pin2) {
      throw ApiException(statusCode: 400, raw: '두 PIN이 일치하지 않습니다.');
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin1)) {
      throw ApiException(statusCode: 400, raw: 'PIN은 숫자 4~6자리여야 합니다.');
    }

    final headers = await API.API.authHeader(); // JWT 있으면 Authorization 붙음
    final uri = Uri.parse(API.API.pinSave(cardNo));
    final res = await http.post(
      uri,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(SetPinReq(pin1: pin1, pin2: pin2).toJson()),
    );

    final text = utf8.decode(res.bodyBytes);
    dynamic jsonBody;
    try {
      jsonBody = text.isNotEmpty ? jsonDecode(text) : null;
    } catch (_) {
      jsonBody = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (jsonBody is Map<String, dynamic>) {
        return PinSaveResult.fromJson(jsonBody);
      }
      // 2xx지만 바디가 없을 때(드뭄)
      return const PinSaveResult(ok: true, message: '저장되었습니다.');
    }

    throw ApiException(statusCode: res.statusCode, body: jsonBody, raw: text);
  }
}
