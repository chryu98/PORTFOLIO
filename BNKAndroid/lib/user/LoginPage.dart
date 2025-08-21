// lib/user/LoginPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';

import '../auth_state.dart';
import '../constants/api.dart';
import '../app_shell.dart';
import 'SelectMemberTypePage.dart';

const kPrimaryRed = Color(0xffB91111);
const kFieldBg = Color(0xFFF4F6FA);
const kFieldStroke = Color(0xFFE6E8EE);
const kTitle = Color(0xFF111111);
const kText = Color(0xFF23272F);
const kHint = Color(0xFF9AA1A9);

class LoginPage extends StatefulWidget {
  final WidgetBuilder? redirectBuilder;

  const LoginPage({super.key, this.redirectBuilder});

  @override
  State<LoginPage> createState() => _LoginPageState();

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

  bool _remember = true;
  bool _loading = false;
  bool _obscure = true;
  String userName = '사용자'; // 클래스 필드

  @override
  void dispose() {
    _idCtl.dispose();
    _pwCtl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading && _idCtl.text.trim().isNotEmpty && _pwCtl.text.trim().isNotEmpty;

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
      final url = Uri.parse(API.jwtLogin);
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _idCtl.text.trim(),
          'password': _pwCtl.text.trim(),
          'remember': _remember,
        }),
      );

      final raw = utf8.decode(res.bodyBytes);
      if (res.statusCode != 200) {
        _showError('서버 오류 (${res.statusCode})');
        return;
      }

      String? access;
      String? refresh;

      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          access = (parsed['accessToken'] ?? parsed['access'] ?? parsed['token'])?.toString();
          refresh = (parsed['refreshToken'] ?? parsed['refresh'])?.toString();
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

      if (access.startsWith('Bearer ')) access = access.substring(7);

      final payload = _decodeJwt(access);
      userName = payload['name']?.toString() ?? '사용자'; // JWT에서 name 추출

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', access);
      await prefs.setString('accessToken', access);
      if (refresh != null && refresh.isNotEmpty) {
        await prefs.setString('refreshToken', refresh);
      }
      await prefs.setBool('remember', _remember);
      await prefs.setString('user_name', userName); // SharedPreferences에 저장

      await AuthState.markLoggedIn(remember: _remember, access: access, refresh: refresh);

      if (!mounted) return;
      final rootNav = Navigator.of(context, rootNavigator: true);
      rootNav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => widget.redirectBuilder?.call(context) ?? const AppShell()),
            (route) => false,
      );

      print('JWT name = $userName');
      print('prefs 저장 완료');

    } catch (e) {
      _showError('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
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
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('로그인', style: TextStyle(color: kTitle, fontSize: 28, fontWeight: FontWeight.w800, height: 1.25)),
                    const SizedBox(height: 6),
                    const Text('BNK 서비스를 안전하게 이용할 수 있도록 로그인해 주세요.', style: TextStyle(color: kText, fontSize: 14)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _idCtl,
                      decoration: _dec('아이디'),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
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
                    SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('자동 로그인', style: TextStyle(fontSize: 15)),
                      value: _remember,
                      activeColor: kPrimaryRed,
                      onChanged: (v) => setState(() => _remember = v),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('비밀번호 찾기'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            text: '아직 회원이 아니신가요? ',
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(
                                text: '회원가입',
                                style: const TextStyle(
                                  color: kPrimaryRed,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SelectMemberTypePage()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: canSubmit ? _login : null,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('로그인'),
            ),
          ),
        ),
      ),
    );
  }
}
