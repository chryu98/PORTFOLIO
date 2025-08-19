// lib/webview/spring_card_editor_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpringCardEditorPage extends StatefulWidget {
  final String url;
  const SpringCardEditorPage({super.key, required this.url});

  @override
  State<SpringCardEditorPage> createState() => _SpringCardEditorPageState();
}

class _SpringCardEditorPageState extends State<SpringCardEditorPage> {
  late final WebViewController _ctrl;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // JS 필수
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100.0),
          onWebResourceError: (err) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('로딩 실패: ${err.description}')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
          title: const Text('커스텀 카드 에디터2'),
          actions: [
            IconButton(
              onPressed: () => _ctrl.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 1
                ? LinearProgressIndicator(value: _progress)
                : const SizedBox(height: 3),
          ),
        ),
        body: WebViewWidget(controller: _ctrl),
      ),
    );
  }
}
