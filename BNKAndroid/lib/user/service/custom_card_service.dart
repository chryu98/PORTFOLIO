// lib/custom/custom_card_service.dart
import 'dart:convert';
import 'package:bnkandroid/constants/api.dart' as API;

enum CustomStatus { pending, approved, rejected, unknown }

CustomStatus parseStatus(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PENDING':  return CustomStatus.pending;
    case 'APPROVED': return CustomStatus.approved;
    case 'REJECTED': return CustomStatus.rejected;
    default:         return CustomStatus.unknown;
  }
}

class CustomCardInfo {
  final int customNo;
  final int memberNo;
  final String status;
  final String? reason;
  final String? aiResult;
  final String? aiReason;
  final String? customService;

  CustomCardInfo({
    required this.customNo,
    required this.memberNo,
    required this.status,
    this.reason,
    this.aiResult,
    this.aiReason,
    this.customService,
  });

  CustomStatus get statusEnum => parseStatus(status);

  factory CustomCardInfo.fromJson(Map<String, dynamic> j) {
    return CustomCardInfo(
      customNo: (j['customNo'] as num).toInt(),
      memberNo: (j['memberNo'] as num).toInt(),
      status: (j['status'] ?? '').toString(),
      reason: j['reason']?.toString(),
      aiResult: j['aiResult']?.toString(),
      aiReason: j['aiReason']?.toString(),
      customService: j['customService']?.toString(),
    );
  }
}

class CustomCardService {
  /// 상세 조회: GET /api/custom-cards/{customNo}
  static Future<CustomCardInfo> fetchOne(int customNo) async {
    final res = await API.API.getJ(_oneUrl(customNo));
    return CustomCardInfo.fromJson(_asMap(res));
  }

  /// 혜택 저장: PUT /api/custom-cards/{customNo}/benefit  body: { customService }
  /// 서버 응답: { "updated": true }
  static Future<bool> saveBenefit({
    required int customNo,
    required String customService,
  }) async {
    final body = jsonEncode({'customService': customService});
    final res = await API.API.putJ(_benefitUrl(customNo), body: body);
    final m = _asMap(res);
    return m['updated'] == true;   // ← 여기만 'ok' → 'updated' 로
  }

  /// 렌더된 이미지 URL: GET /api/custom-cards/{customNo}/image
  static String imageUrl(int customNo) {
    final base = (API.API.baseUrl ?? '').trim();
    final sep = base.endsWith('/') ? '' : '/';
    return base.isEmpty
        ? '/api/custom-cards/$customNo/image'
        : '${base}${sep}api/custom-cards/$customNo/image';
  }

  // ---- 내부 유틸 ----
  static String _oneUrl(int customNo) =>
      API.API.joinBase('/api/custom-cards/$customNo');
  static String _benefitUrl(int customNo) =>
      API.API.joinBase('/api/custom-cards/$customNo/benefit');

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    throw StateError('Unexpected response type: ${v.runtimeType}');
  }
}
