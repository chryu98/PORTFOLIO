// lib/user/service/card_password_service.dart
import 'dart:convert';
import 'package:bnkandroid/constants/api.dart' as API;
import '../model/pin_models.dart';

/// 카드 비밀번호 저장 서비스
class CardPasswordService {
  /// 서버에 PIN 저장(덮어쓰기)
  static Future<PinSaveResult> savePin({
    required int cardNo,
    required String pin1,
    required String pin2,
  }) async {
    // ── 클라이언트 측 1차 검증 (서버도 재검증함)
    if (pin1 != pin2) {
      throw API.ApiException(statusCode: 400, raw: '두 PIN이 일치하지 않습니다.');
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin1)) {
      throw API.ApiException(statusCode: 400, raw: 'PIN은 숫자 4~6자리여야 합니다.');
    }

    // ── 공통 API 유틸 사용 (Authorization/Cookie 자동 부착 + 401 자동 재시도)
    final body = jsonEncode(SetPinReq(pin1: pin1, pin2: pin2).toJson());

    final res = await API.API.postJ(
      API.API.pinSave(cardNo),
      body: body,
    );
    // postJ는 2xx가 아니면 API.ApiException을 throw 하므로 여기까지 왔으면 2xx임

    if (res is Map<String, dynamic>) {
      // 서버 응답: { ok: boolean, message: string }
      return PinSaveResult.fromJson(res);
    }

    // 예외적으로 바디가 맵이 아닐 수 있는 경우 기본 성공 처리
    return const PinSaveResult(ok: true, message: '저장되었습니다.');
  }
}
