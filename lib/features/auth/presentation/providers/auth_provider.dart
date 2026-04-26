import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../repos/data/datasources/github_remote_datasource.dart';
import '../../data/secure_token_storage.dart';
import '../../data/github_device_auth.dart';
import '../../../../core/config/app_config.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, String?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return await SecureTokenStorage.readToken();
  }

  /// Validates a PAT, saves it, and signs in.
  Future<void> verifyAndSave(String token) async {
    state = const AsyncLoading();
    try {
      final client = http.Client();
      try {
        final datasource =
            GitHubRemoteDatasource(client: client, token: token);
        final user = await datasource.getUser();
        await SecureTokenStorage.writeToken(token);
        await SecureTokenStorage.writeUserLogin(user.login);
        state = AsyncData(token);
      } finally {
        client.close();
      }
    } catch (e, st) {
      state = const AsyncData(null);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Saves an OAuth token received from the device flow (already verified
  /// implicitly — if GitHub issued it, it's valid).
  Future<void> saveOAuthToken(String token) async {
    state = const AsyncLoading();
    try {
      final client = http.Client();
      try {
        final datasource =
            GitHubRemoteDatasource(client: client, token: token);
        final user = await datasource.getUser();
        await SecureTokenStorage.writeToken(token);
        await SecureTokenStorage.writeUserLogin(user.login);
        state = AsyncData(token);
      } finally {
        client.close();
      }
    } catch (e, st) {
      state = const AsyncData(null);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> logout() async {
    await SecureTokenStorage.clear();
    state = const AsyncData(null);
  }
}

/// Provides the device-auth helper when a client ID is configured.
final githubDeviceAuthProvider = Provider<GitHubDeviceAuth?>((ref) {
  if (!AppConfig.hasGitHubOAuth) return null;
  return GitHubDeviceAuth(clientId: AppConfig.githubClientId);
});
