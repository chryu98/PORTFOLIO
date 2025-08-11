// lib/faq/model/FaqModel.dart
class FaqModel {
  final int faqNo;
  final String question;
  final String answer;
  final String category;
  final DateTime? regDate;
  final String? writer;
  final String? admin;

  FaqModel({
    required this.faqNo,
    required this.question,
    required this.answer,
    required this.category,
    this.regDate,
    this.writer,
    this.admin,
  });

  factory FaqModel.fromJson(Map<String, dynamic> j) {
    final cat = (j['category'] ?? j['cattegory'] ?? '기타').toString();
    final raw = j['regDate']?.toString();
    DateTime? dt;
    if (raw != null && raw.isNotEmpty) {
      dt = DateTime.tryParse(raw) ?? _tryParseYMDHMS(raw);
    }
    return FaqModel(
      faqNo: (j['faqNo'] ?? j['id']) as int,
      question: j['faqQuestion']?.toString() ?? '',
      answer: j['faqAnswer']?.toString() ?? '',
      category: cat,
      regDate: dt,
      writer: j['writer']?.toString(),
      admin: j['admin']?.toString(),
    );
  }

  static DateTime? _tryParseYMDHMS(String s) {
    try {
      final p = s.split(RegExp(r'[\s:-]')).map(int.parse).toList();
      if (p.length >= 6) return DateTime(p[0], p[1], p[2], p[3], p[4], p[5]);
    } catch (_) {}
    return null;
  }
}
