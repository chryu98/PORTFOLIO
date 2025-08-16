// lib/chat/chat_socket_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bnkandroid/constants/api.dart';

class ChatSocketService {
  Future<Map<String, dynamic>> ask(String userText) async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('jwt_token');

    final uri = Uri.parse('${API.baseUrl}/api/chatbot/ask');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'query': userText}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final j = jsonDecode(resp.body);
        if (j is Map<String, dynamic>) return j;
      } catch (_) {}
      return {'answer': resp.body};
    }

    return {
      'answer': '서버 오류가 발생했습니다. 잠시 후 다시 시도하세요.',
      'found': false,
      'confidence': 0.0,
      'status': resp.statusCode,
    };
  }
}
