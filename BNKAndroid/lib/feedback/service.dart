import 'client.dart';
import 'api.dart';
import 'models.dart';

class FeedbackService {
  final FeedbackHttp _http;
  FeedbackService(this._http);

  Future<FeedbackCreateResp> create(FeedbackCreateReq req) async {
    final json = await _http.postJson(FeedbackApi.create, req.toJson());
    return FeedbackCreateResp.fromJson(json);
  }

  // (옵션) 관리자 요약
  Future<DashboardSummary> getDashboard({int top = 10}) async {
    final json = await _http.getJson(FeedbackApi.dashboard(top: top));
    return DashboardSummary.fromJson(json);
  }
}
