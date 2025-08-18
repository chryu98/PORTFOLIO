// lib/auth_state.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전역 인증 상태
class AuthState {
  // 저장 키
  static const _kAccess = 'jwt_token';
  static const _kRefresh = 'refresh_token';
  static const _kRemember = 'remember_me';
  static const kLastAt = 'last_activity_at'; // ✅ 최근 활동 시각(ms)

  /// 구독 가능한 로그인 상태
  static final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  /// 앱 시작 시 반드시 한 번 호출 (main()에서)
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kAccess);
    final remember = p.getBool(_kRemember) ?? true; // 기본 ON

    // 자동로그인이 켜져 있고 토큰이 있으면 로그인 유지
    loggedIn.value = remember && token != null && token.isNotEmpty;

    if (loggedIn.value) {
      await touchActivity(); // 시작 시각 갱신
    }

    if (kDebugMode) {
      final head = token == null || token.isEmpty
          ? 'null'
          : token.substring(0, token.length > 12 ? 12 : token.length);
      debugPrint('[Auth] init loggedIn=${loggedIn.value} '
          'remember=$remember tokenHead=$head...');
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
    await touchActivity();   // ✅ 활동 시각 기록
    loggedIn.value = true;

    if (kDebugMode) {
      final head = access.substring(0, access.length > 12 ? 12 : access.length);
      debugPrint('[Auth] login saved jwt_token head=$head... remember=$remember');
    }
  }

  /// 로그아웃 시 호출
  static Future<void> markLoggedOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kRemember);
    await p.remove(kLastAt);
    loggedIn.value = false;

    if (kDebugMode) {
      debugPrint('[Auth] logged out (storage cleared)');
    }
  }

  /// 최근 활동 시각(ms) 저장
  static Future<void> touchActivity() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(kLastAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// 토큰을 직접 꺼내 쓸 때
  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  /// (옵션) 디버그 상태 덤프
  static Future<void> debugDump() async {
    final p = await SharedPreferences.getInstance();
    debugPrint('[AUTH] remember=${p.getBool(_kRemember)} '
        'tokenLen=${(p.getString(_kAccess) ?? '').length} '
        'lastAt=${p.getInt(kLastAt)}');
  }
}
