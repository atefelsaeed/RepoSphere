import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../repos/data/datasources/github_remote_datasource.dart';
import '../../data/secure_token_storage.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, String?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return await SecureTokenStorage.readToken();
  }

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

  Future<void> logout() async {
    await SecureTokenStorage.clear();
    state = const AsyncData(null);
  }
}
