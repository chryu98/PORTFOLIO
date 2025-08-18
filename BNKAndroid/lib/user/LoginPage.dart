// lib/user/LoginPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth_state.dart';
import '../constants/api.dart';
import '../app_shell.dart'; // redirect 기본값으로 사용

class LoginPage extends StatefulWidget {
  /// 로그인 성공 후 이동할 대상 화면. 지정 없으면:
  /// - 가드에서 띄워진 경우: pop(true)
  /// - 그 외: AppShell로 교체 이동
  final WidgetBuilder? redirectBuilder;

  const LoginPage({super.key, this.redirectBuilder});

  @override
  State<LoginPage> createState() => _LoginPageState();

  /// 어디서든 호출: 로그인 후 특정 화면으로 교체 이동
  static Future<void> goLoginThen(BuildContext context, WidgetBuilder builder) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(redirectBuilder: builder)),
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  final _idCtl = TextEditingController();
  final _pwCtl = TextEditingController();

  bool _remember = true; // 자동 로그인 기본 ON
  bool _loading = false;

  @override
  void dispose() {
    _idCtl.dispose();
    _pwCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading &&
          _idCtl.text.trim().isNotEmpty &&
          _pwCtl.text.trim().isNotEmpty;

  Future<void> _login() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final url = Uri.parse('${API.baseUrl}/jwt/api/login');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _idCtl.text.trim(),
          'password': _pwCtl.text.trim(),
        }),
      );

      final raw = utf8.decode(res.bodyBytes);
      if (res.statusCode != 200) {
        _showError('서버 오류 (${res.statusCode})');
        return;
      }

      // 응답 파싱
      String? access;
      String? refresh;
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          access  = (data['accessToken'] ?? data['access'] ?? data['token'])?.toString();
          refresh = (data['refreshToken'] ?? data['refresh'])?.toString();
        }
      } catch (_) {
        if (raw.isNotEmpty && !raw.trim().startsWith('<')) {
          access = raw.trim();
        }
      }

      if (access == null || access.isEmpty) {
        _showError('서버에서 액세스 토큰을 받지 못했습니다.');
        return;
      }

      // 상태 저장
      await AuthState.markLoggedIn(
        remember: _remember,
        access: access,
        refresh: refresh,
      );

      if (!mounted) return;

      // ----------------- ✅ 여기부터 성공 후 라우팅 로직 정리 -----------------
      final rootNav = Navigator.of(context, rootNavigator: true);

      if (widget.redirectBuilder != null) {
        // 리디렉트 목적 로그인: 루트 네비게이터로 교체 이동
        rootNav.pushAndRemoveUntil(
          MaterialPageRoute(builder: widget.redirectBuilder!),
              (route) => false,
        );
        return;
      }

      // 가드에서 push<bool>로 띄워졌다면 true 반환(pop)해 작업 계속
      // (루트 스택에 이전 라우트가 존재하는 경우)
      final canPopRoot = await rootNav.maybePop(true);
      if (!canPopRoot) {
        // 루트에 되돌아갈 곳이 없다면 AppShell로 교체
        rootNav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
              (route) => false,
        );
      }
      // ----------------------------------------------------------------------
    } catch (e) {
      _showError('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      useRootNavigator: true, // 루트로 띄우면 중첩 네비게이터 이슈 줄어듦
      builder: (ctx) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit;

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _idCtl,
                  decoration: const InputDecoration(labelText: '아이디'),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),

                TextField(
                  controller: _pwCtl,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _canSubmit ? _login() : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('자동 로그인'),
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? true),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _login : null,
                    child: _loading
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('로그인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
