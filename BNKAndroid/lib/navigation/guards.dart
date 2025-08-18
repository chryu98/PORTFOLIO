// lib/navigation/guards.dart
import 'package:flutter/material.dart';
import 'package:bnkandroid/auth_state.dart';
import 'package:bnkandroid/user/LoginPage.dart';

/// 로그인 필요 작업 실행 가드.
/// 로그인 안 되어 있으면 LoginPage를 rootNavigator로 띄우고,
/// 성공 시 true 리턴 후 [afterLogin]을 수행.
Future<bool> ensureLoggedInAndRun(
    BuildContext context,
    Future<void> Function() afterLogin,
    ) async {
  if (!AuthState.loggedIn.value) {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok != true) return false; // 로그인 취소/실패면 종료
  }
  await afterLogin();
  return true;
}
