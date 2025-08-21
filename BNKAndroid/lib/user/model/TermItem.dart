// lib/user/model/TermItem.dart
import 'dart:convert';
import 'dart:typed_data';

import '../../constants/api.dart';

class TermItem {
  final int pdfNo;
  final String pdfName;
  final bool isRequired;
  final Uint8List? data;

  String get pdfUrl => API.termsPdf(pdfNo);

  bool checked; // 선택(모두 동의 눌렀을 때 미리 체크)
  bool agreed;  // 실제 동의 완료

  TermItem({
    required this.pdfNo,
    required this.pdfName,
    required this.isRequired,
    required this.data,
    this.checked = false,
    this.agreed = false,
  });

  factory TermItem.fromJson(Map<String, dynamic> j) {
    final raw = (j['pdfDataBase64'] as String?)?.trim();
    Uint8List? bytes;
    if (raw != null && raw.isNotEmpty) {
      final cleaned = raw.replaceFirst(RegExp(r'^data:.*;base64,'), '');
      try { bytes = base64Decode(cleaned); } catch (_) { bytes = null; }
    }
    return TermItem(
      pdfNo: (j['pdfNo'] as num).toInt(),
      pdfName: j['pdfName'] as String? ?? '약관',
      isRequired: (j['isRequired'] == 'Y' || j['isRequired'] == 'y' || j['isRequired'] == true),
      data: bytes,
    );
  }
}
