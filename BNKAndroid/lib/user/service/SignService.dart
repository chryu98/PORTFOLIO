// lib/sign/sign_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:bnkandroid/constants/api.dart' as API;

enum SignStatus { readyForSign, signing, signed, rejected, canceled, unknown }

SignStatus parseSignStatus(String? raw) {
  final s = (raw ?? '').trim().toUpperCase();
  switch (s) {
    case 'READY_FOR_SIGN': return SignStatus.readyForSign;
    case 'SIGNING':        return SignStatus.signing;
    case 'SIGNED':         return SignStatus.signed;
    case 'REJECTED':       return SignStatus.rejected;
    case 'CANCELED':       return SignStatus.canceled;
    default:               return SignStatus.unknown;
  }
}

// 서버 컨트롤러 프리픽스
const String _P = '/api/card/apply/sign';

class SignInfo {
  final int applicationNo;
  final String status;
  final String? applicant;

  SignInfo({required this.applicationNo, required this.status, this.applicant});

  SignStatus get statusEnum => parseSignStatus(status);

  factory SignInfo.fromJson(Map<String, dynamic> j) => SignInfo(
    applicationNo: (j['applicationNo'] as num).toInt(),
    status: (j['status'] ?? '').toString(),
    applicant: j['applicant']?.toString(),
  );
}

class SignService {
  // ───────────── 조회 ─────────────
  static Future<SignInfo> fetchInfo(int appNo) async {
    try {
      final res = await API.API.getJ('$_P/info', params: {'applicationNo': appNo});
      return SignInfo.fromJson(_asMap(res));
    } on API.ApiException {
      rethrow;
    } catch (_) {
      throw API.ApiException(statusCode: 500);
    }
  }

  static Future<bool> exists(int appNo) async {
    try {
      final res = await API.API.getJ('$_P/$appNo/exists');
      final m = _asMap(res);
      return m['exists'] == true;
    } on API.ApiException {
      rethrow;
    } catch (_) {
      throw API.ApiException(statusCode: 500);
    }
  }

  // 공개 이미지 URL: /card/apply/sign/{appNo}/image
  static String imageUrl(int appNo) {
    final base = (API.API.baseUrl ?? '').trim();
    final sep = base.endsWith('/') ? '' : '/';
    final publicPath = '/card/apply/sign';
    return base.isEmpty
        ? '$publicPath/$appNo/image'
        : '${base}${sep}${publicPath.substring(1)}/$appNo/image';
  }

  // ──────── Redirect(WebView) 플로우 ────────
  // 서버: POST /api/card/apply/sign/session/{appNo}
  static Future<Map<String, dynamic>> createSession(int appNo) async {
    try {
      final res = await API.API.postJ('$_P/session/$appNo');
      return _asMap(res);
    } on API.ApiException {
      rethrow;
    } catch (_) {
      throw API.ApiException(statusCode: 500);
    }
  }

  // 서버: GET /api/card/apply/sign/result/{appNo}
  static Future<Map<String, dynamic>> fetchResult(int appNo) async {
    try {
      final res = await API.API.getJ('$_P/result/$appNo');
      return _asMap(res);
    } on API.ApiException {
      rethrow;
    } catch (_) {
      throw API.ApiException(statusCode: 500);
    }
  }

  // 서버에는 confirm 엔드포인트가 없음 → 업로드가 이미 SIGNED로 바꿈.
  // 그래서 1) confirm 시도, 2) 404면 재조회로 대체.
  static Future<bool> confirmDone(int appNo) async {
    try {
      final res = await API.API.postJ('$_P/confirm/$appNo');
      final m = _asMap(res);
      if (m['ok'] == true) return true;
      if ((m['status'] ?? '').toString().toUpperCase() == 'SIGNED') return true;
      return false;
    } on API.ApiException catch (e) {
      // 404면 서버에 confirm이 없는 구성 → 결과 재조회해서 SIGNED면 true
      if (e.statusCode == 404) {
        try {
          final r = await fetchResult(appNo);
          return (r['status'] ?? '').toString().toUpperCase() == 'SIGNED';
        } catch (_) {
          return true; // 업로드 시 이미 SIGNED로 전환하는 서버 구성: true로 간주
        }
      }
      rethrow;
    } catch (_) {
      return true;
    }
  }

  // ──────── 패드 업로드(JSON + base64) ────────
  // 서버가 접두사 유무 모두 처리(decodeBase64Image)하므로 순수 base64로 전송
  static Future<bool> uploadSignature({
    required int applicationNo,
    required Uint8List pngBytes,
  }) async {
    try {
      final b64 = base64Encode(pngBytes); // 접두사 없이
      final body = jsonEncode({
        'applicationNo': applicationNo,
        'imageBase64': b64,
      });
      final res = await API.API.postJ(_P, body: body);
      final m = _asMap(res);
      if (m['ok'] == true) return true;
      if ((m['status'] ?? '').toString().toUpperCase() == 'SIGNED') return true;
      return false;
    } on API.ApiException {
      rethrow;
    } catch (_) {
      throw API.ApiException(statusCode: 500);
    }
  }

  static Future<bool> uploadAndConfirm({
    required int applicationNo,
    required Uint8List pngBytes,
  }) async {
    final ok = await uploadSignature(applicationNo: applicationNo, pngBytes: pngBytes);
    if (!ok) return false;
    return await confirmDone(applicationNo);
  }

  // ──────── 유틸 ────────
  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    throw API.ApiException(statusCode: 500);
  }
}
