// lib/user/model/term_item.dart
import 'dart:convert';
import 'dart:typed_data';

class TermItem {
  final int pdfNo;
  final String pdfName;
  final bool isRequired;   // 'Y' -> true
  final Uint8List? data;   // pdfDataBase64 -> bytes

  bool checked;  // 목록 체크
  bool agreed;   // PDF 뷰어에서 '동의' 눌렀는지

  TermItem({
    required this.pdfNo,
    required this.pdfName,
    required this.isRequired,
    required this.data,
    this.checked = false,
    this.agreed = false,
  });

  factory TermItem.fromJson(Map<String, dynamic> j) {
    final b64 = j['pdfDataBase64'] as String?;
    return TermItem(
      pdfNo: (j['pdfNo'] as num).toInt(),
      pdfName: (j['pdfName'] as String?) ?? '약관',
      isRequired: j['isRequired'] == 'Y',
      data: b64 != null ? base64Decode(b64) : null,
    );
  }
}
