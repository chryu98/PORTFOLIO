// lib/postcode/postcode_search_page_web.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html; // 웹 전용 iframe
import 'dart:convert';
import 'package:flutter/material.dart';

// ✅ 핵심: 웹용 platformViewRegistry 는 'dart:ui_web' 에 있다
import 'dart:ui_web' as ui_web;

class PostcodeSearchPage extends StatefulWidget {
  const PostcodeSearchPage({super.key});
  @override
  State<PostcodeSearchPage> createState() => _PostcodeSearchPageState();
}

class _PostcodeSearchPageState extends State<PostcodeSearchPage> {
  late final html.IFrameElement _iframe;
  static const String _viewType = 'postcode-iframe-view';
  html.EventListener? _listener;

  @override
  void initState() {
    super.initState();

    // 1) iframe 생성: Flutter Web 의 /assets/postcode.html 로드
    _iframe = html.IFrameElement()
      ..src = 'assets/postcode.html'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';

    // 2) 뷰 팩토리 등록 (ui_web 사용)
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
            (int _) => _iframe,
      );
    } catch (_) {
      // 일부 에디터에서 red underline 떠도 실제 빌드는 통과함
    }

    // 3) 자식(iframe) → 부모(Flutter Web) 메시지 수신
    _listener = (event) {
      final e = event as html.MessageEvent;
      final raw = e.data;

      Map<String, dynamic>? msg;

      if (raw is Map) {
        msg = raw.map((k, v) => MapEntry(k.toString(), v));
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            msg = decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
      }

      if (msg == null) return;
      if (msg['type']?.toString() != 'postcode') return;

      final payload = msg['payload'];
      if (payload is Map) {
        Navigator.pop(
          context,
          payload.map((k, v) => MapEntry(k.toString(), v)),
        );
      } else if (payload is String) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          Navigator.pop(context, data);
        } catch (_) {
          Navigator.pop(context);
        }
      } else {
        Navigator.pop(context);
      }
    };

    html.window.addEventListener('message', _listener!, false);
  }

  @override
  void dispose() {
    if (_listener != null) {
      html.window.removeEventListener('message', _listener!, false);
      _listener = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('우편번호 찾기')),
      body: const HtmlElementView(viewType: _viewType),
    );
  }
}
