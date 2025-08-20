import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'register.dart'; // ← 조건부 등록

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

    // Web일 때만 실제 웹 구현체를 등록 (모바일/데스크톱은 no-op)
    registerWebViewImplementations();

    final params = PlatformWebViewControllerCreationParams();

    _ctrl = WebViewController.fromPlatformCreationParams(params)
    // JS는 모바일에서만 설정 (웹은 설정 메서드가 의미 없음)
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

    // 모바일에서만 JS 모드 설정
    if (!kIsWeb) {
      _ctrl.setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    // (선택) 안드로이드 전용 설정이 필요하면 별도 helper로 조건부 처리하세요.
    // → webview_flutter_android 를 직접 import 하지 않는 편이 안전합니다.
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
