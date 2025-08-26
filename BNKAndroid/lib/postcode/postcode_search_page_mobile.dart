import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle; // ← 추가

class PostcodeSearchPage extends StatefulWidget {
  const PostcodeSearchPage({super.key});
  @override
  State<PostcodeSearchPage> createState() => _PostcodeSearchPageState();
}

class _PostcodeSearchPageState extends State<PostcodeSearchPage> {
  late final WebViewController _ctl;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _ctl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'App',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            Navigator.pop(context, data);
          } catch (_) {
            Navigator.pop(context);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(onProgress: (p) => setState(() => _progress = p / 100.0)),
      );

    _loadHtmlFromAssetWithHttpsBase(); // ★ 여기서 로드
  }

  Future<void> _loadHtmlFromAssetWithHttpsBase() async {
    final html = await rootBundle.loadString('assets/postcode.html');
    // webview_flutter 4.x는 baseUrl 지원합니다.
    await _ctl.loadHtmlString(
      html,
      baseUrl: 'https://postcode.local/', // 임의의 https 오리진 (도메인 아무거나 가능)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우편번호 찾기'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 1.0 ? LinearProgressIndicator(value: _progress) : const SizedBox(height: 3),
        ),
      ),
      body: WebViewWidget(controller: _ctl),
    );
  }
}
