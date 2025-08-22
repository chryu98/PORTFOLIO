import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class ApiException implements Exception {
  final int status;
  final String body;
  ApiException(this.status, this.body);
  @override
  String toString() => 'ApiException($status): $body';
}

class FeedbackHttp {
  final _client = http.Client();

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${FeedbackApi.baseUrl}$path');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('${FeedbackApi.baseUrl}$path');
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }
}
