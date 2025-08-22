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
      API.API.pinSave(cardNo), // e.g. /card/apply/api/card-password/{cardNo}/pin
      body: body,
    );
    // postJ는 2xx가 아니면 API.ApiException throw

    if (res is Map<String, dynamic>) {
      // 서버 응답: { ok: boolean, message: string }
      return PinSaveResult.fromJson(res);
    }

    // 예외적으로 바디가 맵이 아닐 수 있는 경우 기본 성공 처리
    return const PinSaveResult(ok: true, message: '저장되었습니다.');
  }

  /// 편의: PIN 저장 성공 후 바로 승격까지 수행
  ///
  /// - applicationNo: CARD_APPLICATION(_TEMP)의 신청 번호
  /// - cardNo/pin1/pin2: 기존과 동일
  ///
  /// 성공 시 true, 실패 시 ApiException throw
  static Future<bool> savePinAndPromote({
    required int applicationNo,
    required int cardNo,
    required String pin1,
    required String pin2,
  }) async {
    final pinRes = await savePin(cardNo: cardNo, pin1: pin1, pin2: pin2);
    if (pinRes.ok != true) {
      // 서버가 ok:false를 돌려준 예외 상황
      throw API.ApiException(statusCode: 400, raw: pinRes.message ?? 'PIN 저장 실패');
    }

    // PIN 저장 성공 → 승격 호출
    final promoted = await _promote(applicationNo);
    if (promoted) return true;

    // 서버에서 비표준 형태가 온 경우 메시지 보강
    throw API.ApiException(statusCode: 500, raw: '승격 실패(알 수 없는 응답)');
  }

  /// 승격 API 호출 (TEMP → FINAL)
  /// - 성공(status: promoted | already_promoted) → true
  /// - 404(temp_not_found) 또는 기타 에러 → ApiException
  static Future<bool> _promote(int applicationNo) async {
    // API 유틸에 promote 경로 도우미가 있다면 사용하세요:
    // final url = API.API.promote(applicationNo);
    // 없다면 절대/상대 경로로 직접 넘겨도 됩니다( postJ 가 baseUrl 붙여줌 ):
    final url = '/api/card/apply/promote/$applicationNo';

    final res = await API.API.postJ(url);
    // res 예: { status: 'promoted' } | { status: 'already_promoted' }

    if (res is Map<String, dynamic>) {
      final status = (res['status'] ?? '').toString();
      if (status == 'promoted' || status == 'already_promoted') return true;
      if (status == 'temp_not_found') {
        throw API.ApiException(statusCode: 404, raw: '신청서를 찾을 수 없습니다.');
      }
      throw API.ApiException(statusCode: 500, raw: '승격 실패: $status');
    }

    // 바디가 맵이 아닐 경우도 성공으로 간주(서버가 최소 200 OK)
    return true;
  }
}
