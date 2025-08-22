class FeedbackApi {
  // 에뮬레이터면 10.0.2.2, 실기기면 PC의 IP로 변경
  static const String baseUrl = 'http://192.168.0.5:8090';

  static const String create = '/api/feedback';
  // (옵션) 관리자 요약
  static String dashboard({int top = 10}) =>
      '/admin/feedback/summary.json?top=$top';
}
