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
  final String? reason;        // 반려 사유
  final String? aiResult;      // ACCEPT / REJECT
  final String? aiReason;      // AI 거절 사유
  final String? customService; // 기존 저장된 혜택 설명

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
  /// 상세 조회: GET /api/custom-card/{customNo}
  static Future<CustomCardInfo> fetchOne(int customNo) async {
    final res = await API.API.getJ(API.API.customCardOne(customNo));
    return CustomCardInfo.fromJson(_asMap(res));
  }

  /// 혜택 저장: PUT /api/custom-card/{customNo}/benefit  body: { customService }
  static Future<bool> saveBenefit({
    required int customNo,
    required String customService,
  }) async {
    final body = jsonEncode({'customService': customService});
    final res = await API.API.putJ(API.API.customCardBenefit(customNo), body: body);
    final m = _asMap(res);
    return m['ok'] == true;
  }

  /// 렌더된 이미지 URL (서버 @GetMapping("/api/custom-card/{customNo}/image") 가정)
  static String imageUrl(int customNo) {
    final base = (API.API.baseUrl ?? '').trim();
    final sep = base.endsWith('/') ? '' : '/';
    return base.isEmpty
        ? '/api/custom-card/$customNo/image'
        : '${base}${sep}api/custom-card/$customNo/image';
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    throw StateError('Unexpected response type: ${v.runtimeType}');
  }
}
