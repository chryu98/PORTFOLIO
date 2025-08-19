// lib/webview/spring_card_editor_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class SpringCardEditorPage extends StatefulWidget {
  final String url; // 예: http://10.0.2.2:8090/editor/card
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

    // 1) 플랫폼별 생성 파라미터로 컨트롤러 만들기 (Android 전용 설정을 쓰기 위함)
    final PlatformWebViewControllerCreationParams params =
    const PlatformWebViewControllerCreationParams();

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // JSP에서 JS 필수
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100.0),
          onNavigationRequest: (req) {
            // 필요 시 특정 스킴/도메인 차단/허용 로직 추가
            return NavigationDecision.navigate;
          },
          onWebResourceError: (err) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('로딩 실패: ${err.errorCode} ${err.description}')),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // 2) Android 전용 편의 설정 (디버깅/미디어 자동재생 등)
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
      // 필요 시 혼합 콘텐츠 허용 등 추가 가능:
      // (controller.platform as AndroidWebViewController)
      //     .setAllowsContentAccess(true);
      // (controller.platform as AndroidWebViewController)
      //     .setAllowsFileAccess(true);
    }

    _ctrl = controller;
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
          actions: [
            IconButton(
              tooltip: '새로고침',
              onPressed: () async {
                try {
                  await _ctrl.reload();
                } catch (_) {}
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 1.0
                ? LinearProgressIndicator(value: _progress)
                : const SizedBox(height: 3),
          ),
        ),
        body: WebViewWidget(controller: _ctrl),
      ),
    );
  }
}
