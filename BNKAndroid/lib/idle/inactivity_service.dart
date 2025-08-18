// lib/idle/inactivity_service.dart  (경로는 프로젝트에 맞춰주세요)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_shell.dart';
import '../auth_state.dart';

/// 15분 무활동 시 자동 로그아웃
class InactivityService with WidgetsBindingObserver {
  InactivityService._();
  static final InactivityService instance = InactivityService._();

  /// 마지막 활동 시각을 저장하는 키 (ms since epoch)
  static const _kLastAt = 'last_activity_at';

  /// 무활동 한계/경고 시점
  Duration idleLimit = const Duration(minutes: 15);
  Duration warnBefore = const Duration(minutes: 1);
  // Duration idleLimit = const Duration(seconds: 10);
  // Duration warnBefore = const Duration(seconds: 5);

  Timer? _warnTimer;
  Timer? _logoutTimer;
  BuildContext? _ctx;

  // ───────────────── lifecycle attachment ─────────────────

  void attachLifecycle() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detachLifecycle() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void start(BuildContext context) {
    _ctx = context;
    _markActivityNow(); // 시작 시각 기록
    _restartTimers();
  }

  void stop() {
    _warnTimer?.cancel();
    _logoutTimer?.cancel();
    _warnTimer = null;
    _logoutTimer = null;
  }

  /// 사용자 활동이 있을 때마다 호출해 주세요(터치/스크롤 등)
  void ping() {
    if (!AuthState.loggedIn.value) return;
    _markActivityNow();
    _restartTimers();
  }

  // ───────────────── WidgetsBindingObserver ─────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkElapsedSinceLastActivity();
    }
  }

  // ───────────────── internal helpers ─────────────────

  Future<void> _markActivityNow() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _checkElapsedSinceLastActivity() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getInt(_kLastAt) ?? 0;
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
      useRootNavigator: true, // ✅ 루트로 띄워 중첩 네비 문제 방지
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('자동 로그아웃 안내'),
        content: Text('활동이 없어 ${remain}초 후 자동 로그아웃됩니다. 계속 이용하려면 아무 곳이나 터치하세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              ping(); // 연장
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
    if (ctx == null || !ctx.mounted) return;

    final nav = Navigator.of(ctx, rootNavigator: true);

    // 열려 있는 화면을 안전하게 모두 닫고
    while (await nav.maybePop()) {}

    // 홈(AppShell)로 복귀
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
    );

    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('활동이 없어 자동 로그아웃되었습니다.')),
    );
  }
}
