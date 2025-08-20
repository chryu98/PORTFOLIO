// lib/webview/spring_card_editor_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 웹(Chrome) 구현체 & 플랫폼 인터페이스
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// (모바일 전용) 안드로이드 옵션 필요 시
import 'package:webview_flutter_android/webview_flutter_android.dart';

class SpringCardEditorPage extends StatefulWidget {
  /// 예: http://10.0.2.2:8090/editor/card
  final String url;
  const SpringCardEditorPage({super.key, required this.url});

  @override
  State<SpringCardEditorPage> createState() => _SpringCardEditorPageState();
}

class _SpringCardEditorPageState extends State<SpringCardEditorPage> {
  late final WebViewController _ctrl;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // ✅ 웹(Chrome) 경로: 구현 등록 + 웹 전용 생성자 사용 (setJavaScriptMode 호출 금지)
      WebViewPlatform.instance = WebWebViewPlatform();
      final params = PlatformWebViewControllerCreationParams();

      _ctrl = WebViewController.fromPlatformCreationParams(params)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (p) => setState(() => _progress = p / 100.0),
            onWebResourceError: (err) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('로딩 실패: ${err.errorCode} ${err.description}')),
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // ✅ 모바일(iOS/Android) 경로
      final params = const PlatformWebViewControllerCreationParams();

      final controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted) // 모바일에서만 사용
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (p) => setState(() => _progress = p / 100.0),
            onWebResourceError: (err) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('로딩 실패: ${err.errorCode} ${err.description}')),
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));

      // (선택) 안드로이드 전용 추가 설정
      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      _ctrl = controller;
    }
  }

  Future<bool> _onWillPop() async {
    if (await _ctrl.canGoBack()) {
      _ctrl.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('커스텀 카드 에디터'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 1.0
                ? LinearProgressIndicator(value: _progress)
                : const SizedBox(height: 3),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _ctrl.reload(),
            ),
          ],
        ),
        body: WebViewWidget(controller: _ctrl),
      ),
    );
  }
}
