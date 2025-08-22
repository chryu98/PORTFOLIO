class FeedbackCreateReq {
  final int cardNo;
  final int? userNo;
  final int rating;     // 1~5
  final String comment;

  FeedbackCreateReq({
    required this.cardNo,
    this.userNo,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
    'cardNo': cardNo,
    'userNo': userNo,
    'rating': rating,
    'comment': comment,
  };
}

class FeedbackCreateResp {
  final int feedbackNo;
  FeedbackCreateResp(this.feedbackNo);

  factory FeedbackCreateResp.fromJson(Map<String, dynamic> j) =>
      FeedbackCreateResp(j['feedbackNo'] as int);
}

// (옵션) 관리자 요약 미리보기용
class KeywordStat {
  final String keyword;
  final int count;
  KeywordStat({required this.keyword, required this.count});

  factory KeywordStat.fromJson(Map<String, dynamic> j) =>
      KeywordStat(keyword: j['keyword'] as String, count: (j['count'] as num).toInt());
}

class DashboardSummary {
  final double positiveRatio;
  final double negativeRatio;
  final double avgRating;
  final List<KeywordStat> topKeywords;

  DashboardSummary({
    required this.positiveRatio,
    required this.negativeRatio,
    required this.avgRating,
    required this.topKeywords,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
    positiveRatio: (j['positiveRatio'] as num?)?.toDouble() ?? 0,
    negativeRatio: (j['negativeRatio'] as num?)?.toDouble() ?? 0,
    avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0,
    topKeywords: ((j['topKeywords'] as List?) ?? [])
        .map((e) => KeywordStat.fromJson({
      'keyword': e['keyword'],
      'count': e['count'],
    }))
        .toList(),
  );
}
