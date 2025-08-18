// lib/auth_state.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전역 인증 상태
class AuthState {
  // 저장 키(단일화)
  static const _kAccess = 'jwt_token';
  static const _kRefresh = 'refresh_token';
  static const _kRemember = 'remember_me';

  /// 구독 가능한 로그인 상태
  static final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  /// 앱 시작 시 반드시 한 번 호출하세요 (main() 또는 Splash에서)
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kAccess);
    loggedIn.value = t != null && t.isNotEmpty;

    if (kDebugMode) {
      final head = t == null || t.isEmpty
          ? 'null'
          : t.substring(0, t.length > 12 ? 12 : t.length);
      // ignore: avoid_print
      print('[Auth] init loggedIn=${loggedIn.value} tokenHead=$head...');
    }
  }

  /// 로그인 성공 시 호출
  static Future<void> markLoggedIn({
    required bool remember,
    required String access,
    String? refresh,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    await p.setBool(_kRemember, remember);
    if (refresh != null && refresh.isNotEmpty) {
      await p.setString(_kRefresh, refresh);
    }
    loggedIn.value = true;

    if (kDebugMode) {
      final head =
      access.substring(0, access.length > 12 ? 12 : access.length);
      // ignore: avoid_print
      print('[Auth] login saved jwt_token head=$head...');
    }
  }

  /// 로그아웃 시 호출
  static Future<void> markLoggedOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kRemember);
    loggedIn.value = false;

    if (kDebugMode) {
      // ignore: avoid_print
      print('[Auth] logged out (storage cleared)');
    }
  }

  /// 필요 시 직접 토큰을 가져와 사용할 때
  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }
}
