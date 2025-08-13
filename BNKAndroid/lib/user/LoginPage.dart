import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'CardListPage.dart';
import 'package:bnkandroid/constants/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await API.initBaseUrl(); // baseUrl 먼저 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JWT 로그인 예제',
      home: SplashPage(), // 시작 시 토큰 체크
    );
  }
}

/// 시작 페이지 - 토큰 체크
class SplashPage extends StatefulWidget {
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

    if (token != null && token.isNotEmpty) {
      print("🔹 저장된 토큰 있음 → 메인으로 이동");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CardListPage()),
      );
    } else {
      print("🔹 저장된 토큰 없음 → 로그인으로 이동");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _savedToken;

  Future<void> login() async {
    // 1) 현재 로그인 URL이 실제 서버와 맞는지 꼭 확인
    //    ※ 서버에 /jwt/api/login 이 없다면 /user/api/login 으로 바꾸세요.
    final loginUrl = '${API.baseUrl}/jwt/api/login';
    print('[LOGIN] url=$loginUrl');

    try {
      final resp = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        // 서버 DTO 필드명에 정확히 맞추세요 (username/password 혹은 id/pw)
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final raw = utf8.decode(resp.bodyBytes);
      print('[LOGIN] status=${resp.statusCode}');
      print('[LOGIN] content-type=${resp.headers['content-type']}');
      print('[LOGIN] body="$raw"'); // 실제 응답이 뭔지 먼저 확인!

      if (resp.statusCode != 200) {
        // 401/404/500 등은 body가 HTML이거나 빈 문자열일 수 있음
        _showErrorDialog('서버 오류 (${resp.statusCode})');
        return;
      }

      // 2) JSON 시도 → 실패 시 텍스트 토큰 시도 → 둘 다 실패면 에러
      String? token;
      try {
        final dynamic parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          token = (parsed['token'] ?? parsed['accessToken'])?.toString();
        }
      } catch (_) {
        // JSON이 아니면 텍스트 통째로 토큰으로 가정 (서버가 text/plain 토큰만 내려줄 때 대비)
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
      setState(() => _savedToken = token);
      print('✅ JWT 저장 완료');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CardListPage()),
      );
    } catch (e) {
      _showErrorDialog('네트워크 오류: $e');
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
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
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('로그인'),
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
