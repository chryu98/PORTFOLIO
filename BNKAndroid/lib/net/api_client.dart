// lib/net/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bnkandroid/constants/api.dart';

class ApiClient {
  /// 기본 헤더
  static Map<String, String> baseHeaders({Map<String, String>? extra}) => {
    'Content-Type': 'application/json',
    if (extra != null) ...extra,
  };

  /// Authorization: Bearer <jwt_token> 포함 헤더
  static Future<Map<String, String>> authHeaders(
      {Map<String, String>? extra}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (token.isEmpty) {
      throw StateError('JWT 토큰이 없습니다. (authHeaders)');
    }
    return baseHeaders(extra: {
      'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    });
  }

  // GET (인증)
  static Future<http.Response> getAuth(String pathOrUrl,
      {Map<String, String>? query}) async {
    final uri = _toUri(pathOrUrl, query: query);
    return http.get(uri, headers: await authHeaders());
  }

  // POST (인증)
  static Future<http.Response> postAuth(String pathOrUrl, Object body,
      {Map<String, String>? query}) async {
    final uri = _toUri(pathOrUrl, query: query);
    return http.post(uri, headers: await authHeaders(), body: jsonEncode(body));
  }

  // PUT (인증)
  static Future<http.Response> putAuth(String pathOrUrl, Object body,
      {Map<String, String>? query}) async {
    final uri = _toUri(pathOrUrl, query: query);
    return http.put(uri, headers: await authHeaders(), body: jsonEncode(body));
  }

  static Uri _toUri(String pathOrUrl, {Map<String, String>? query}) {
    final isAbsolute = pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
    final url = isAbsolute ? pathOrUrl : '${API.baseUrl}$pathOrUrl';
    return Uri.parse(url).replace(queryParameters: {
      if (Uri.parse(url).queryParameters.isNotEmpty)
        ...Uri.parse(url).queryParameters,
      if (query != null) ...query,
    });
  }
}
