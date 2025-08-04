// lib/services/admin_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApiService {
  final String baseUrl;

  AdminApiService({this.baseUrl = "http://localhost:8090"}); // 실제 서버 주소로 수정 필요

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/admin/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('로그인 실패: ${response.statusCode}');
    }
  }
}
