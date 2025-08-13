// lib/auth/token_store.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kKey = 'jwt';
  static final TokenStore I = TokenStore._();
  TokenStore._();

  Future<void> save(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kKey, token);
  }

  Future<String?> get() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kKey);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kKey);
  }
}
