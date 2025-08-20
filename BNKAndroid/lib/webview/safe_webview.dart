import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

// 웹 구현체/플랫폼 인터페이스
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// 에셋을 문자열로 읽을 때 필요
import 'package:flutter/services.dart' show rootBundle;

/// 웹/모바일 겸용 안전 컨트롤러 생성
WebViewController createSafeWebViewController() {
  if (kIsWeb) {
    // 웹 구현 등록 + 웹 전용 생성자
    WebViewPlatform.instance = WebWebViewPlatform();
    final params = PlatformWebViewControllerCreationParams();
    final c = WebViewController.fromPlatformCreationParams(params);
    // ❌ 웹에서는 setJavaScriptMode 호출하지 않음 (미구현)
    return c;
  } else {
    // ✅ 모바일에서만 JS 모드 설정
    final c = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
    return c;
  }
}

/// 에셋 HTML을 로드(웹: 문자열 주입 / 모바일: 에셋 로드)
extension SafeAssetLoad on WebViewController {
  Future<void> loadAssetHtml(String assetPath) async {
    if (kIsWeb) {
      final html = await rootBundle.loadString(assetPath);
      await loadHtmlString(html);
    } else {
      await loadFlutterAsset(assetPath);
    }
  }
}
