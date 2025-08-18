// lib/security/screenshot_watcher.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot_callback/screenshot_callback.dart';

/// 스크린샷 감지 전용 싱글톤 (screenshot_callback ^3.0.1 대응)
class ScreenshotWatcher {
  ScreenshotWatcher._();
  static final ScreenshotWatcher instance = ScreenshotWatcher._();

  ScreenshotCallback? _cb;
  bool _running = false;

  /// 스크린샷 감지를 시작한다.
  /// - 웹/데스크톱: noop
  /// - Android/iOS에서만 동작
  void start(BuildContext context) {
    if (_running) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    try {
      final cb = ScreenshotCallback();
      // v3.0.1은 addListener만 제공 (onScreenshot Stream 없음)
      cb.addListener(() => _onShot(context));
      _cb = cb;
      _running = true;
    } catch (_) {
      _running = false;
    }
  }

  void _onShot(BuildContext ctx) {
    HapticFeedback.mediumImpact();
    if (!ctx.mounted) return;

    final m = ScaffoldMessenger.maybeOf(ctx);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      const SnackBar(
        content: Text('보안: 화면 캡처가 감지되었습니다. 민감 정보 노출에 주의하세요.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 감지를 중단한다. (해당 화면 dispose에서 호출)
  Future<void> stop() async {
    try {
      await _cb?.dispose();
    } catch (_) {}
    _cb = null;
    _running = false;
  }
}
