// lib/idle/inactivity_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_shell.dart';
import '../auth_state.dart';

class InactivityService with WidgetsBindingObserver {
  InactivityService._();
  static final InactivityService instance = InactivityService._();

  Duration idleLimit = const Duration(minutes: 15);
  Duration warnBefore = const Duration(minutes: 1);

  Timer? _warnTimer;
  Timer? _logoutTimer;
  BuildContext? _ctx;
  bool _firstResume = true;

  void attachLifecycle() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detachLifecycle() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void start(BuildContext context) {
    _ctx = context;
    _firstResume = true;
    AuthState.touchActivity();
    _restartTimers();
  }

  void stop() {
    _warnTimer?.cancel();
    _logoutTimer?.cancel();
    _warnTimer = null;
    _logoutTimer = null;
    _ctx = null; // ✅ 컨텍스트 정리
  }

  void ping() {
    if (!AuthState.loggedIn.value) return;
    AuthState.touchActivity();
    _restartTimers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_firstResume) {
        _firstResume = false;
        _restartTimers();
        return;
      }
      _checkElapsedSinceLastActivity();
    }
  }

  Future<void> _checkElapsedSinceLastActivity() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getInt(AuthState.kLastAt) ?? 0;
    if (last == 0) {
      _restartTimers();
      return;
    }
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    if (elapsed >= idleLimit.inMilliseconds) {
      await _forceLogout();
    } else {
      _restartTimers();
    }
  }

  void _restartTimers() {
    _warnTimer?.cancel();
    _logoutTimer?.cancel();

    if (warnBefore > Duration.zero && warnBefore < idleLimit) {
      _warnTimer = Timer(idleLimit - warnBefore, _showWarningIfStillIdle);
    }
    _logoutTimer = Timer(idleLimit, _forceLogout);
  }

  void _showWarningIfStillIdle() {
    final ctx = _ctx;
    if (ctx == null || !AuthState.loggedIn.value) return;

    final remain = warnBefore.inSeconds;

    showDialog(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('자동 로그아웃 안내'),
        content: Text('활동이 없어 ${remain}초 후 자동 로그아웃됩니다. 계속 이용하려면 아무 곳이나 터치하세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              ping(); // 세션 연장
            },
            child: const Text('계속 이용'),
          ),
        ],
      ),
    );
  }

  Future<void> _forceLogout() async {
    stop();
    if (!AuthState.loggedIn.value) return;

    await AuthState.markLoggedOut();

    final ctx = _ctx;
    if (ctx == null) return;
    // SDK 호환용 mounted 체크(없어도 동작은 함)
    if (ctx is Element && !ctx.mounted) return;

    final nav = Navigator.of(ctx, rootNavigator: true);

    // 열려있는 라우트 정리
    while (nav.canPop()) {
      nav.pop();
    }

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
    );

    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('활동이 없어 자동 로그아웃되었습니다.')),
    );
  }
}
