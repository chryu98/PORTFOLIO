import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'CardListPage.dart';
import 'package:bnkandroid/constants/api.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await API.initBaseUrl();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      title: '로그인 예제',
      home: LoginPage(),
    );
  }
}

// 로그인 페이지 위젯
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 사용자 입력을 받기 위한 컨트롤러 (아이디, 비밀번호)
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _savedToken;

  // 로그인 버튼 클릭 시 호출되는 함수
  Future<void> login() async {
    // 1. Spring API URL 설정
    final url = Uri.parse('http://192.168.0.229:8090/user/api/login');

    try {
      // 2. POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // JSON 전송
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      // 3. 응답 상태 코드에 따라 처리
      if (response.statusCode == 200) {
        // 로그인 성공
        final data = jsonDecode(response.body);
        print('로그인 성공: ${data['message']}');

        // 토큰이 응답에 포함되어 있다면 저장
        if (data['token'] != null) {
          String token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          // 상태 변경하여 화면에 토큰 표시
          setState(() {
            _savedToken = token;
          });

          print('JWT 토큰 저장 완료: $token');
        } else {
          print('응답에 토큰이 없습니다.');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CardListPage()),
        );

      } else if (response.statusCode == 401) {
        // 로그인 실패 (아이디/비밀번호 오류 or 중복로그인 등)
        final data = jsonDecode(response.body);
        _showErrorDialog(data['message']);
      } else {
        // 기타 오류 (서버 오류 등)
        _showErrorDialog('서버 오류가 발생했습니다.');
      }

    } catch (e) {
      print('네트워크 오류: $e');
      // 네트워크 오류 등 예외 처리
      _showErrorDialog('네트워크 오류가 발생했습니다.');
    }
  }

  // 에러 메시지를 보여주는 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 간단한 로그인 UI 구성
    return Scaffold(
      appBar: AppBar(title: Text('로그인')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이디 입력창
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '아이디'),
            ),
            SizedBox(height: 10),
            // 비밀번호 입력창
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true, // 비밀번호 숨김 처리
            ),
            SizedBox(height: 20),
            // 로그인 버튼
            ElevatedButton(
              onPressed: login, // 로그인 함수 호출
              child: Text('로그인'),
            ),
            if (_savedToken != null) ...[
              SizedBox(height: 20),
              Text('저장된 토큰:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_savedToken!),
            ]
          ],
        ),
      ),
    );
  }
}
