

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // 필요 시

class CardEditorPage extends StatefulWidget {
  const CardEditorPage({super.key});

  @override
  State<CardEditorPage> createState() => _CardEditorPageState();
}

class _CardEditorPageState extends State<CardEditorPage> {
  late final WebViewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AppBridge',
        onMessageReceived: _onFromWeb,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          // 필요 시 초기 데이터 주입
          // await _ctrl.runJavaScript('window.init && window.init(${jsonEncode({...})})');
        },
      ))
      ..loadFlutterAsset('assets/editor/index.html');
  }

  Future<void> _onFromWeb(JavaScriptMessage msg) async {
    final m = jsonDecode(msg.message);
    switch (m['type']) {
      case 'READY':
      // 웹이 준비됨
        break;

      case 'SAVE_IMAGE':
        final payload = m['payload'] as Map<String, dynamic>;
        final filename = (payload['filename'] as String?) ?? 'custom_card.png';
        final base64Str = (payload['base64'] as String?) ?? '';

        if (base64Str.isEmpty) return;

        try {
          // (선택) Android 13 미만 외부 저장소 권한 요청
          // await Permission.storage.request();

          final bytes = base64Decode(base64Str);
          final dir = await getTemporaryDirectory(); // 임시 폴더에 저장 후 공유
          final file = File('${dir.path}/$filename');
          await file.writeAsBytes(bytes);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 저장 완료 (공유창 열기)')),
          );

          // 갤러리 저장 대신 공유 시트 띄우기 (다운로드 폴더 저장을 원하면 SAF/MediaStore 처리)
          await Share.shareXFiles([XFile(file.path)], text: '커스텀 카드');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e')),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카드 커스텀 에디터')),
      body: WebViewWidget(controller: _ctrl),
    );
  }
}
