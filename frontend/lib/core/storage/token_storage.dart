import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT — secure storage on mobile/desktop, SharedPreferences on web.
class TokenStorage {
  static const _key = 'jwt_token';

  final FlutterSecureStorage _secureStorage;

  TokenStorage(this._secureStorage);

  Future<void> write(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
      return;
    }
    await _secureStorage.write(key: _key, value: token);
  }

  Future<String?> read() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    }
    return _secureStorage.read(key: _key);
  }

  Future<void> delete() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      return;
    }
    await _secureStorage.delete(key: _key);
  }
}
