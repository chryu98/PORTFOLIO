// lib/user/LoginPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth_state.dart';
import '../constants/api.dart';
import '../app_shell.dart'; // redirect 기본값으로 사용

const kPrimaryRed = Color(0xffB91111);
const kFieldBg = Color(0xFFF4F6FA);
const kFieldStroke = Color(0xFFE6E8EE);
const kTitle = Color(0xFF111111);
const kText = Color(0xFF23272F);
const kHint = Color(0xFF9AA1A9);

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
  bool _obscure = true;

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

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kHint, fontSize: 16),
    filled: true,
    fillColor: kFieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kFieldStroke),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kPrimaryRed, width: 1.2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kFieldStroke),
    ),
  );

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
      final rootNav = Navigator.of(context, rootNavigator: true);

      if (widget.redirectBuilder != null) {
        rootNav.pushAndRemoveUntil(
          MaterialPageRoute(builder: widget.redirectBuilder!),
              (route) => false,
        );
        return;
      }

      final popped = await rootNav.maybePop(true);
      if (!popped) {
        rootNav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
              (route) => false,
        );
      }
    } catch (e) {
      _showError('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit;

    return Scaffold(
      backgroundColor: Colors.white,
      // 상단 AppBar 대신 토스처럼 얇은 헤더 + 큰 타이틀
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    splashRadius: 22,
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(),
                  ),
                ],
              ),
            ),

            // 본문
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 큰 타이틀
                    const Text(
                      '로그인',
                      style: TextStyle(
                        color: kTitle,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'BNK 서비스를 안전하게 이용할 수 있도록 로그인해 주세요.',
                      style: TextStyle(color: kText, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // 아이디
                    TextField(
                      controller: _idCtl,
                      decoration: _dec('아이디'),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // 비밀번호 + 보기 토글
                    TextField(
                      controller: _pwCtl,
                      decoration: _dec('비밀번호').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          color: kHint,
                        ),
                      ),
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _canSubmit ? _login() : null,
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 10),

                    // 자동 로그인 (스위치형, 토스 느낌)
                    SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('자동 로그인', style: TextStyle(fontSize: 15)),
                      value: _remember,
                      activeColor: kPrimaryRed,
                      onChanged: (v) => setState(() => _remember = v),
                    ),

                    // (선택) 비밀번호 찾기
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: 라우팅 연결 시 여기에
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('비밀번호 찾기'),
                      ),
                    ),

                    const SizedBox(height: 80), // 하단 버튼과 간격 확보
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 하단 고정 CTA 버튼 (토스 느낌)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? kPrimaryRed : const Color(0x33B91111),
                foregroundColor: Colors.white,
                elevation: canSubmit ? 0 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: canSubmit ? _login : null,
              child: _loading
                  ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('로그인'),
            ),
          ),
        ),
      ),
    );
  }
}
