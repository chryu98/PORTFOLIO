import 'dart:async';
import 'package:flutter/material.dart';
import 'ws_push_service.dart';
import 'push_message.dart';

/// 어디서든 호출 가능한 푸시 싱글톤
class PushConnector {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static WsPushService? _ws;
  static StreamSubscription<PushMessage>? _sub;

  /// 시작: 로그인 직후 등에서 호출
  static Future<void> start({
    required String baseUrl,  // 예: http://192.168.0.5:8090
    required int memberNo,
    String? bearerToken,      // 서버가 헤더 검사할 때만 사용
  }) async {
    // ws:// 또는 wss:// 로 안전하게 변환
    final base = Uri.parse(baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/push',
      queryParameters: {'memberNo': memberNo.toString()},
    );

    final headers = (bearerToken == null || bearerToken.isEmpty)
        ? null
        : <String, dynamic>{'Authorization': 'Bearer $bearerToken'};

    await _ws?.close();
    _ws = WsPushService(wsUri, headers: headers);
    await _ws!.connect();

    await _sub?.cancel();
    _sub = _ws!.stream.listen((m) {
      // 앱 어디서든 스낵바로 보여줌
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${m.title}\n${m.content}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  /// 중지: 로그아웃 시 호출
  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _ws?.close();
    _ws = null;
  }
}
