import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'CardListPage.dart';
import 'package:bnkandroid/constants/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await API.initBaseUrl(); // baseUrl 먼저 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JWT 로그인 예제',
      home: const SplashPage(), // 시작 시 토큰 체크
    );
  }
}

/// 시작 페이지 - 토큰 체크
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // 🔹 저장된 토큰 있음 → 메인으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  CardListPage()),
      );
    } else {
      // 🔹 저장된 토큰 없음 → 로그인으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  /// 로그인 성공 후 이동할 대상 (예: () => ApplicationStep1Page(...))
  final WidgetBuilder? redirectBuilder;

  const LoginPage({super.key, this.redirectBuilder});

  @override
  _LoginPageState createState() => _LoginPageState();

  /// 어디서든 호출: 로그인 후 특정 화면으로 교체 이동
  static Future<void> goLoginThen(BuildContext context, WidgetBuilder builder) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(redirectBuilder: builder)),
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _savedToken;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // ✅ 입력 변화 시 버튼 활성화 상태 갱신
    _usernameController.addListener(_onFieldsChanged);
    _passwordController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onFieldsChanged);
    _passwordController.removeListener(_onFieldsChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {}); // build 재실행 → 버튼 활성/비활성 갱신
  }

  bool get _canSubmit =>
      !_loading &&
          _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;

  Future<void> _login() async {
    // 간단 검증
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요.')),
      );
      return;
    }

    final loginUrl = '${API.baseUrl}/jwt/api/login'; // 서버 엔드포인트 확인 필요
    setState(() => _loading = true);

    try {
      final resp = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        // 서버 DTO 필드명에 맞춰 수정 (username/password 또는 id/pw 등)
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final raw = utf8.decode(resp.bodyBytes);

      if (resp.statusCode != 200) {
        _showErrorDialog('서버 오류 (${resp.statusCode})');
        return;
      }

      // JSON 토큰 파싱 → 실패 시 text/plain 토큰 시도
      String? token;
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          token = (parsed['token'] ?? parsed['accessToken'])?.toString();
        }
      } catch (_) {
        if (raw.isNotEmpty && !raw.trim().startsWith('<')) {
          token = raw.trim();
        }
      }

      if (token == null || token.isEmpty) {
        _showErrorDialog('서버에서 토큰을 받지 못했습니다.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      _savedToken = token;

      if (!mounted) return;

      // ✅ 리다이렉트 대상이 있으면 그곳으로, 없으면 메인으로
      if (widget.redirectBuilder != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: widget.redirectBuilder!),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CardListPage()),
        );
      }
    } catch (e) {
      _showErrorDialog('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: '아이디'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_canSubmit) _login(); // 엔터로 로그인
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canSubmit ? _login : null, // ✅ 활성/비활성 정상 동작
                child: _loading
                    ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('로그인'),
              ),
            ),
            if (_savedToken != null) ...[
              const SizedBox(height: 20),
              const Text('저장된 토큰:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_savedToken!),
            ]
          ],
        ),
      ),
    );
  }
}

/// 토큰 자동 추가 HTTP 클라이언트
class AuthorizedClient {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw Exception('저장된 토큰이 없습니다.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> get(String url) async {
    return http.get(Uri.parse(url), headers: await _headers());
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    return http.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body) async {
    return http.put(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> delete(String url) async {
    return http.delete(Uri.parse(url), headers: await _headers());
  }
}
