// lib/sign/sign_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:bnkandroid/constants/api.dart' as API;

/// 서명 상태
enum SignStatus {
  readyForSign,
  signing,
  signed,
  rejected,
  canceled,
  unknown,
}

SignStatus parseSignStatus(String? raw) {
  final s = (raw ?? '').trim().toUpperCase();
  switch (s) {
    case 'READY_FOR_SIGN':
      return SignStatus.readyForSign;
    case 'SIGNING':
      return SignStatus.signing;
    case 'SIGNED':
      return SignStatus.signed;
    case 'REJECTED':
      return SignStatus.rejected;
    case 'CANCELED':
      return SignStatus.canceled;
    default:
      return SignStatus.unknown;
  }
}

/// 최종(FINAL) 신청서의 서명/상태 정보
class SignInfo {
  final int applicationNo;
  final String status;     // READY_FOR_SIGN | SIGNING | SIGNED ...
  final String? applicant; // 선택

  SignInfo({
    required this.applicationNo,
    required this.status,
    this.applicant,
  });

  SignStatus get statusEnum => parseSignStatus(status);

  factory SignInfo.fromJson(Map<String, dynamic> j) => SignInfo(
    applicationNo: (j['applicationNo'] as num).toInt(),
    status: (j['status'] ?? '').toString(),
    applicant: j['applicant']?.toString(),
  );
}

/// 전자서명 전용 API 래퍼
///
/// 서버 엔드포인트(예시):
/// - GET  /api/card/apply/sign/info?applicationNo=:appNo
/// - POST /api/card/apply/sign/session                (리다이렉트/패드 세션 생성)
/// - GET  /api/card/apply/sign/result?applicationNo=:appNo
/// - POST /api/card/apply/sign/confirm/{appNo}
/// - POST /api/card/apply/sign                        (패드 업로드: { applicationNo, imageBase64 })
/// - GET  /api/card/apply/sign/:appNo/exists
/// - GET  /card/apply/sign/:appNo/image               (공개 이미지 뷰어)
class SignService {
  // ───────────────────────────────────────────
  // 공통 조회
  // ───────────────────────────────────────────

  /// FINAL 에서 서명 대상 정보 조회
  static Future<SignInfo> fetchInfo(int appNo) async {
    final res = await API.API.getJ(
      '/api/card/apply/sign/info',
      params: {'applicationNo': appNo},
    );
    return SignInfo.fromJson(_asMap(res));
  }

  /// 해당 신청번호의 서명 존재여부
  /// GET /api/card/apply/sign/{appNo}/exists  -> { exists: true|false }
  static Future<bool> exists(int appNo) async {
    final res = await API.API.getJ('/api/card/apply/sign/$appNo/exists');
    final m = _asMap(res);
    return m['exists'] == true;
  }

  /// (뷰어용) 서명 이미지 절대 URL (백엔드에 @GetMapping("/card/apply/sign/{appNo}/image"))
  static String imageUrl(int appNo) {
    final base = (API.API.baseUrl ?? '').trim();
    final sep = base.endsWith('/') ? '' : '/';
    return base.isEmpty
        ? '/card/apply/sign/$appNo/image'
        : '${base}${sep}card/apply/sign/$appNo/image';
  }

  // ───────────────────────────────────────────
  // Redirect(WebView) 플로우
  // ───────────────────────────────────────────

  /// 서명 세션 생성
  /// return: { "type": "redirect", "url": "https://..." } 또는 { "type": "pad", ... }
  static Future<Map<String, dynamic>> createSession(int appNo) async {
    final body = jsonEncode({'applicationNo': appNo});
    final res = await API.API.postJ('/api/card/apply/sign/session', body: body);
    return _asMap(res);
  }

  /// 서명 결과 조회 (서버 판단값)
  /// return: { "status": "SIGNED" | "SIGNING" | "READY_FOR_SIGN" ... }
  static Future<Map<String, dynamic>> fetchResult(int appNo) async {
    final res = await API.API.getJ(
      '/api/card/apply/sign/result',
      params: {'applicationNo': appNo},
    );
    return _asMap(res);
  }

  /// 서명 완료 확정 → FINAL.STATUS = 'SIGNED'
  static Future<bool> confirmDone(int appNo) async {
    final res = await API.API.postJ('/api/card/apply/sign/confirm/$appNo');
    final m = _asMap(res);
    return m['ok'] == true || (m['status']?.toString().toUpperCase() == 'SIGNED');
  }

  // ───────────────────────────────────────────
  // 패드 업로드 플로우
  // ───────────────────────────────────────────

  /// 사인 이미지(PNG 바이트) 업로드
  /// body: { applicationNo, imageBase64: "data:image/png;base64,..." }
  ///
  /// ⚠️ 백엔드가 업로드 시점에 바로 SIGNED 로 바꾸도록 구현했다면 이 호출만으로 완료됩니다.
  static Future<bool> uploadSignature({
    required int applicationNo,
    required Uint8List pngBytes,
  }) async {
    final dataUrl = 'data:image/png;base64,${base64Encode(pngBytes)}';
    final body = jsonEncode({
      'applicationNo': applicationNo,
      'imageBase64': dataUrl,
    });
    final res = await API.API.postJ('/api/card/apply/sign', body: body);
    final m = _asMap(res);
    // 백엔드 응답이 { ok: true, status: 'SIGNED' } 형태면 그대로 통과
    if (m['ok'] == true) return true;
    // 일부 서버는 ok 없이 status 만 줄 수도 있음
    if ((m['status'] ?? '').toString().toUpperCase() == 'SIGNED') return true;
    return false;
  }

  /// 업로드 후 곧바로 상태를 `SIGNED` 로 확정까지 한 번에 처리
  /// - 서버가 업로드 시점에 SIGNED 로 만들지 않는 구성일 때 사용.
  static Future<bool> uploadAndConfirm({
    required int applicationNo,
    required Uint8List pngBytes,
  }) async {
    final ok = await uploadSignature(
      applicationNo: applicationNo,
      pngBytes: pngBytes,
    );
    if (!ok) return false;
    // 업로드 결과가 true여도, 혹시 READY 상태인 서버 구성을 대비해 confirm 호출
    final confirmed = await confirmDone(applicationNo);
    return confirmed;
  }

  // ───────────────────────────────────────────
  // 유틸
  // ───────────────────────────────────────────

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      // Map<dynamic,dynamic> → Map<String,dynamic>
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    throw StateError('Unexpected response type: ${v.runtimeType}');
  }
}
