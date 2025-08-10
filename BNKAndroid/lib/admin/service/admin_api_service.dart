import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService {
  static final _client = http.Client();
  static String? _sessionId;
  final String baseUrl;

  AdminApiService({this.baseUrl = "http://192.168.0.222:8090"});

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sessionId');
  }

  bool isLoggedIn() => _sessionId != null;

  Future<void> _saveSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', sessionId);
    _sessionId = sessionId;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/admin/login');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.contains('JSESSIONID')) {
      final parsed = _parseSessionId(setCookie);
      print('[디버그] 받은 JSESSIONID: $parsed'); // 추가
      if (parsed != null) {
        await _saveSession(parsed);
        print('[디버그] 세션 저장 완료'); // 추가
      }
    } else {
      print('[디버그] Set-Cookie 헤더 없음'); // 추가
    }


    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('로그인 실패: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAdminInfo() async {
    final url = Uri.parse('$baseUrl/admin/info');

    final response = await _client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_sessionId != null) 'Cookie': 'JSESSIONID=$_sessionId',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('관리자 정보 조회 실패: ${response.statusCode}');
    }
  }


  String? _parseSessionId(String rawCookie) {
    final jsessionid = RegExp(r'JSESSIONID=([^;]+)').firstMatch(rawCookie);
    return jsessionid?.group(1);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionId');
    _sessionId = null;
  }
}
