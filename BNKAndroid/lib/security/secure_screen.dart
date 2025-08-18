// lib/security/secure_screen.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:screenshot_callback/screenshot_callback.dart';

typedef ScreenshotHandler = void Function();

/// 이 위젯으로 감싸면:
/// 1) 스크린샷/녹화 차단(모바일)
/// 2) 스크린샷 시 스낵바 알림
/// 3) 앱 복귀 시 보안 상태 재적용
class SecureScreen extends StatefulWidget {
  final Widget child;
  final ScreenshotHandler? onScreenshot;

  const SecureScreen({
    super.key,
    required this.child,
    this.onScreenshot,
  });

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> with WidgetsBindingObserver {
  final _cb = ScreenshotCallback();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecure();
    _startScreenshotWatch();
  }

  Future<void> _enableSecure() async {
    if (kIsWeb) return; // 웹은 미지원
    try {
      await ScreenProtector.preventScreenshotOn();
      if (Platform.isIOS) {
        await ScreenProtector.protectDataLeakageOn();
      }
    } catch (e) {
      debugPrint('[SecureScreen] enable failed: $e');
    }
  }

  Future<void> _disableSecure() async {
    if (kIsWeb) return;
    try {
      await ScreenProtector.preventScreenshotOff();
      if (Platform.isIOS) {
        await ScreenProtector.protectDataLeakageOff();
      }
    } catch (e) {
      debugPrint('[SecureScreen] disable failed: $e');
    }
  }

  void _startScreenshotWatch() {
    if (kIsWeb) return;
    try {
      _cb.addListener(() {
        widget.onScreenshot?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('캡처가 감지되었습니다. 개인정보 보호를 위해 캡처가 제한됩니다.'),
            ),
          );
        }
      });
      // v3.0.1에서는 initialize()를 호출해야 합니다.
      _cb.initialize();
    } catch (e) {
      debugPrint('[SecureScreen] screenshot listen failed: $e');
    }
  }

  void _stopScreenshotWatch() {
    try {
      _cb.dispose();
    } catch (e) {
      debugPrint('[SecureScreen] dispose failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableSecure();
    }
  }

  @override
  void dispose() {
    _stopScreenshotWatch();
    WidgetsBinding.instance.removeObserver(this);
    _disableSecure(); // 이 화면 벗어나면 다시 허용
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
