import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'screenshot_watcher.dart';

typedef ScreenshotHandler = void Function();

/// 이 위젯으로 감싸면:
/// 1) 스크린샷/녹화 차단(모바일)
/// 2) 스크린샷/녹화 시 스낵바 알림
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
  bool get _isMobile =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecure();
    if (_isMobile) {
      ScreenshotWatcher.instance.start(context);
    }
  }

  Future<void> _enableSecure() async {
    if (!_isMobile) return;
    try {
      await ScreenProtector.preventScreenshotOn();   // Android/iOS 스크린샷 차단
      await ScreenProtector.protectDataLeakageOn();  // iOS 데이터 유출 보호(안드 no-op)
    } catch (e) {
      debugPrint('[SecureScreen] enable failed: $e');
    }
  }

  Future<void> _disableSecure() async {
    if (!_isMobile) return;
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      debugPrint('[SecureScreen] disable failed: $e');
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
    if (_isMobile) {
      ScreenshotWatcher.instance.stop();
    }
    WidgetsBinding.instance.removeObserver(this);
    _disableSecure();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
