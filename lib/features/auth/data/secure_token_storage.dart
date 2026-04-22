import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'github_pat';
  static const _userLoginKey = 'github_user_login';

  static Future<String?> readToken() => _storage.read(key: _tokenKey);
  static Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readUserLogin() =>
      _storage.read(key: _userLoginKey);
  static Future<void> writeUserLogin(String login) =>
      _storage.write(key: _userLoginKey, value: login);

  static Future<void> clear() => _storage.deleteAll();
}
