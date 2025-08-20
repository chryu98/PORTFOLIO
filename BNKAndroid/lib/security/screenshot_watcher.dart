import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screen_capture_event_stub.dart'
if (dart.library.io) 'package:screen_capture_event/screen_capture_event.dart';

/// 스크린샷 감지 전용 싱글톤 (Web/데스크톱은 noop, Android/iOS만 동작)
class ScreenshotWatcher {
  ScreenshotWatcher._();
  static final ScreenshotWatcher instance = ScreenshotWatcher._();

  final _event = ScreenCaptureEvent();
  bool _started = false;

  bool get _isMobile =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> start(BuildContext context) async {
    if (_started || !_isMobile) return;
    _started = true;

    try {
      // ✅ 반환형이 void 이므로 await 금지
      _event.addScreenShotListener((_) => _onShot(context));
      _event.addScreenRecordListener((_) => _onRecord(context));
    } catch (e) {
      debugPrint('[ScreenshotWatcher] start failed: $e');
      _started = false;
    }
  }

  void _onShot(BuildContext ctx) {
    HapticFeedback.mediumImpact();
    if (!ctx.mounted) return;
    final m = ScaffoldMessenger.maybeOf(ctx);
    m?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('보안: 화면 캡처가 감지되었습니다. 민감 정보 노출에 주의하세요.'),
        duration: Duration(seconds: 2),
      ));
  }

  void _onRecord(BuildContext ctx) {
    if (!ctx.mounted) return;
    final m = ScaffoldMessenger.maybeOf(ctx);
    m?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('보안: 화면 녹화가 감지되었습니다. 민감 정보 노출에 주의하세요.'),
        duration: Duration(seconds: 2),
      ));
  }

  Future<void> stop() async {
    if (!_started) return;
    try {
      // ✅ 반환형이 void 이므로 await 금지
      _event.dispose();
    } catch (e) {
      debugPrint('[ScreenshotWatcher] stop failed: $e');
    }
    _started = false;
  }
}
