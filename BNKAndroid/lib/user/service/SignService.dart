// lib/sign/sign_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:bnkandroid/constants/api.dart' as API;

class SignInfo {
  final int applicationNo;
  final String status;     // READY_FOR_SIGN | SIGNING | SIGNED ...
  final String? applicant; // 선택
  SignInfo({required this.applicationNo, required this.status, this.applicant});

  factory SignInfo.fromJson(Map<String, dynamic> j) => SignInfo(
    applicationNo: (j['applicationNo'] as num).toInt(),
    status: (j['status'] ?? '').toString(),
    applicant: j['applicant']?.toString(),
  );
}

/// 전자서명 전용 API 래퍼 (사인패드 업로드 플로우)
class SignService {
  /// FINAL에서 서명 대상 정보 조회
  /// GET /api/card/apply/sign/info?applicationNo=:appNo
  static Future<SignInfo> fetchInfo(int appNo) async {
    final res = await API.API.getJ(
      '/api/card/apply/sign/info',
      params: {'applicationNo': appNo},
    );
    return SignInfo.fromJson(res as Map<String, dynamic>);
  }

  /// 사인 이미지(PNG 바이트) 업로드
  /// POST /api/card/apply/sign  body: { applicationNo, imageBase64: "data:image/png;base64,..." }
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
    return res is Map && (res['ok'] == true);
  }

  /// 해당 신청번호의 서명 존재여부
  /// GET /api/card/apply/sign/{appNo}/exists  -> { exists: true|false }
  static Future<bool> exists(int appNo) async {
    final res = await API.API.getJ('/api/card/apply/sign/$appNo/exists');
    return (res is Map) && (res['exists'] == true);
  }

  /// (뷰어용) 서명 이미지 절대 URL
  /// GET으로 바로 표시 가능: Image.network(SignService.imageUrl(appNo))
  static String imageUrl(int appNo) {
    final base = (API.API.baseUrl ?? '').trim();
    final sep = base.endsWith('/') ? '' : '/';
    // 백엔드 컨트롤러: @GetMapping("/card/apply/sign/{appNo}/image")
    // 공개 GET(permitAll)로 설정되어 있어야 함
    return base.isEmpty
        ? '/card/apply/sign/$appNo/image'
        : '${base}${sep}card/apply/sign/$appNo/image';
  }
}
