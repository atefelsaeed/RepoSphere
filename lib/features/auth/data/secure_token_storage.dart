import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // GitHub
  static Future<String?> readToken() =>
      _storage.read(key: StorageKeys.githubToken);
  static Future<void> writeToken(String token) =>
      _storage.write(key: StorageKeys.githubToken, value: token);
  static Future<String?> readUserLogin() =>
      _storage.read(key: StorageKeys.githubUserLogin);
  static Future<void> writeUserLogin(String login) =>
      _storage.write(key: StorageKeys.githubUserLogin, value: login);

  // GitLab
  static Future<String?> readGitLabToken() =>
      _storage.read(key: StorageKeys.gitlabToken);
  static Future<void> writeGitLabToken(String token) =>
      _storage.write(key: StorageKeys.gitlabToken, value: token);
  static Future<void> deleteGitLabToken() =>
      _storage.delete(key: StorageKeys.gitlabToken);

  static Future<void> clear() => _storage.deleteAll();
}
