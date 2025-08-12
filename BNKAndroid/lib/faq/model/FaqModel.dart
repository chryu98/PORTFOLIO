// lib/faq/model/FaqModel.dart
class FaqModel {
  final int faqNo;
  final String faqQuestion;
  final String faqAnswer;
  final DateTime? regDate;
  final String writer;
  final String admin;
  final String category; // 서버는 cattegory(오타)지만 내부에선 category로 통일

  FaqModel({
    required this.faqNo,
    required this.faqQuestion,
    required this.faqAnswer,
    required this.regDate,
    required this.writer,
    required this.admin,
    required this.category,
  });

  factory FaqModel.fromJson(Map<String, dynamic> j) {
    // 날짜: "yyyy-MM-dd HH:mm:ss"일 수 있으니 공백을 T로 바꿔 시도
    DateTime? parsed;
    final raw = (j['regDate'] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    }

    return FaqModel(
      faqNo: (j['faqNo'] ?? 0) is int
          ? (j['faqNo'] as int)
          : int.tryParse(j['faqNo']?.toString() ?? '0') ?? 0,

      // 문자열은 전부 toString()으로 널 방어
      faqQuestion: (j['faqQuestion'] ?? '').toString(),
      faqAnswer: (j['faqAnswer'] ?? '').toString(),
      regDate: parsed,
      writer: (j['writer'] ?? '').toString(),
      admin: (j['admin'] ?? '').toString(),
      // cattegory(오타) or category 둘 다 흡수, 기본값 '기타'
      category: (j['cattegory'] ?? j['category'] ?? '기타').toString(),
    );
  }
}
