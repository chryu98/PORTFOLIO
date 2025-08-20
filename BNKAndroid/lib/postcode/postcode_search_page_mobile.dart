import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
        'App', // postcode.html에서 window.App.postMessage(...) 호출
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            Navigator.pop(context, data); // 결과 전달
          } catch (_) {
            Navigator.pop(context);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100.0),
        ),
      )
      ..loadFlutterAsset('assets/postcode.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우편번호 찾기'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 1.0
              ? LinearProgressIndicator(value: _progress)
              : const SizedBox(height: 3),
        ),
      ),
      body: WebViewWidget(controller: _ctl),
    );
  }
}
