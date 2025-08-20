// Web 전용 구현 등록
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

void registerWebViewImplementations() {
  WebViewPlatform.instance = WebWebViewPlatform();
}
