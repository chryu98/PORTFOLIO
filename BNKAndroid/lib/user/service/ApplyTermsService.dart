// lib/user/service/apply_terms_service.dart
import 'dart:convert';
import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/model/TermItem.dart';

class ApplyTermsService {
  /// 약관 목록 + PDF(Base64) 조회
  /// GET /api/card/apply/card-terms?cardNo=
  static Future<List<TermItem>> fetchTerms({required int cardNo}) async {
    final json = await API.getJ(
      API.termsListByCard,            // ✅ 경로 상수 사용
      params: {'cardNo': cardNo},
    );
    final List list = json as List;
    return list
        .map((e) => TermItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 로그인 사용자 정보 (memberNo) 조회
  /// GET /api/card/apply/customer-info?cardNo=  (JWT 필요)
  static Future<int> fetchMemberNo({required int cardNo}) async {
    final h = await API.authHeader();
    // ignore: avoid_print
    print('[ApplyTermsService] header=$h');
    final json = await API.getJ(
      API.customerInfo,
      params: {'cardNo': cardNo},
      headers: h,
    );
    return (json['loginUser']['memberNo'] as num).toInt();
  }

  /// 약관 동의 저장
  /// POST /api/card/apply/terms-agree  (JWT 권장)
  static Future<void> saveAgreements({
    required int memberNo,
    required int cardNo,
    required List<int> pdfNos,
  }) async {
    final body = jsonEncode({
      'memberNo': memberNo,
      'cardNo': cardNo,
      'pdfNos': pdfNos,
    });

    await API.postJ(
      API.termsAgree,                 // ✅ 경로 상수 사용
      body: body,
      headers: await API.authHeader(),// ✅ Bearer 토큰
    );
  }
}
