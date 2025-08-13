// lib/net/authorized_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/token_store.dart';

class AuthorizedClient {
  final http.Client _inner;
  AuthorizedClient({http.Client? inner}) : _inner = inner ?? http.Client();

  Future<Map<String, String>> _headers(Map<String, String>? extra) async {
    final token = await TokenStore.I.get();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final h = await _headers(headers);
    final res = await _inner.get(Uri.parse(url), headers: h);
    return res;
  }

  Future<http.Response> post(String url, {Object? json, Map<String, String>? headers}) async {
    final h = await _headers(headers);
    final body = json == null ? null : jsonEncode(json);
    final res = await _inner.post(Uri.parse(url), headers: h, body: body);
    return res;
  }
}
