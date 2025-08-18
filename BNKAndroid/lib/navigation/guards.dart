// lib/navigation/guards.dart
import 'package:flutter/material.dart';
import '../auth_state.dart';
import '../user/LoginPage.dart';

/// 로그인되어 있지 않으면 로그인 화면을 루트로 띄우고,
/// 로그인 후 [action]을 실행한다.
Future<void> ensureLoggedInAndRun(
    BuildContext context,
    Future<void> Function() action,
    ) async {
  // ✅ AuthState가 초기화되어 있고, 현재 로그인 상태면 바로 실행
  if (AuthState.loggedIn.value) {
    await action();
    return;
  }

  // ✅ 로그인 페이지를 루트 네비게이터로 띄움
  final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );

  // ✅ 로그인 성공 시: ok == true 이거나, 전역 상태가 true로 바뀌었으면 계속
  if (ok == true || AuthState.loggedIn.value) {
    await action();
  }
}
