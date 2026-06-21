import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/git/git_provider_type.dart';
import '../domain/git_connection.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Multi-account connections ────────────────────────────────────────────

  /// Reads all connections, migrating legacy single-account tokens on first run.
  static Future<List<GitConnection>> readConnections() async {
    final raw = await _storage.read(key: StorageKeys.connections);
    if (raw != null && raw.isNotEmpty) return GitConnection.decodeList(raw);

    final migrated = await _migrateLegacyTokens();
    if (migrated.isNotEmpty) {
      await _storage.write(
        key: StorageKeys.connections,
        value: GitConnection.encodeList(migrated),
      );
    }
    return migrated;
  }

  static Future<void> writeConnections(List<GitConnection> connections) =>
      _storage.write(
        key: StorageKeys.connections,
        value: GitConnection.encodeList(connections),
      );

  /// Builds connections from the old `github_pat` / `gitlab_pat` keys so users
  /// upgrading from the single-account version keep their sessions.
  static Future<List<GitConnection>> _migrateLegacyTokens() async {
    final result = <GitConnection>[];

    final ghToken = await _storage.read(key: StorageKeys.githubToken);
    if (ghToken != null && ghToken.isNotEmpty) {
      final login = await _storage.read(key: StorageKeys.githubUserLogin);
      result.add(GitConnection(
        id: newConnectionId(),
        type: GitProviderType.github,
        accountLogin: login ?? 'github',
        token: ghToken,
      ));
    }

    final glToken = await _storage.read(key: StorageKeys.gitlabToken);
    if (glToken != null && glToken.isNotEmpty) {
      result.add(GitConnection(
        id: newConnectionId(),
        type: GitProviderType.gitlab,
        accountLogin: 'gitlab',
        token: glToken,
      ));
    }

    return result;
  }

  static String newConnectionId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(0x7fffffff);
    return '$ts-$rand';
  }

  static Future<void> clear() => _storage.deleteAll();

  // ─── Legacy single-account API (kept for migration / compatibility) ─────────

  static Future<String?> readToken() =>
      _storage.read(key: StorageKeys.githubToken);
  static Future<void> writeToken(String token) =>
      _storage.write(key: StorageKeys.githubToken, value: token);
  static Future<String?> readUserLogin() =>
      _storage.read(key: StorageKeys.githubUserLogin);
  static Future<void> writeUserLogin(String login) =>
      _storage.write(key: StorageKeys.githubUserLogin, value: login);

  static Future<String?> readGitLabToken() =>
      _storage.read(key: StorageKeys.gitlabToken);
  static Future<void> writeGitLabToken(String token) =>
      _storage.write(key: StorageKeys.gitlabToken, value: token);
  static Future<void> deleteGitLabToken() =>
      _storage.delete(key: StorageKeys.gitlabToken);
}
