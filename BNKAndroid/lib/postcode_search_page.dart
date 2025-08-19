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

  @override
  void initState() {
    super.initState();
    _ctl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'App',
        onMessageReceived: (msg) {
          final data = jsonDecode(msg.message) as Map<String, dynamic>;
          Navigator.pop(context, data); // 선택 결과 리턴
        },
      )
      ..loadFlutterAsset('assets/postcode.html'); // ← 아까 만든 html 로드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('우편번호 찾기')),
      body: WebViewWidget(controller: _ctl),
    );
  }
}
