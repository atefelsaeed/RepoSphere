import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../repos/data/datasources/github_remote_datasource.dart';
import '../../data/secure_token_storage.dart';
import '../../data/github_device_auth.dart';
import '../../data/supabase_auth_service.dart';
import '../../../../core/config/app_config.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, String?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<String?> {
  StreamSubscription<AuthState>? _supabaseSub;

  @override
  Future<String?> build() async {
    ref.onDispose(() => _supabaseSub?.cancel());

    // 1. Check SecureStorage (PAT or Device Flow token)
    final localToken = await SecureTokenStorage.readToken();
    if (localToken != null && localToken.isNotEmpty) return localToken;

    // 2. Check active Supabase session (OAuth redirect callback)
    if (AppConfig.hasSupabase) {
      _listenToSupabase();
      final providerToken =
          Supabase.instance.client.auth.currentSession?.providerToken;
      if (providerToken != null) return providerToken;
    }

    return null;
  }

  void _listenToSupabase() {
    _supabaseSub?.cancel();
    _supabaseSub = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          final token = data.session?.providerToken;
          if (token != null && token.isNotEmpty) {
            state = AsyncData(token);
          }
        case AuthChangeEvent.signedOut:
          await SecureTokenStorage.clear();
          state = const AsyncData(null);
        default:
          break;
      }
    });
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

  /// Saves an OAuth token from Device Flow (GitHub already verified it).
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
    _supabaseSub?.cancel();
    await SecureTokenStorage.clear();
    if (AppConfig.hasSupabase) {
      await Supabase.instance.client.auth.signOut();
    }
    state = const AsyncData(null);
  }
}

/// Device Flow helper — null when no GitHub OAuth client ID is configured.
final githubDeviceAuthProvider = Provider<GitHubDeviceAuth?>((ref) {
  if (!AppConfig.hasGitHubOAuth) return null;
  return GitHubDeviceAuth(clientId: AppConfig.githubClientId);
});

/// Supabase auth service — null when Supabase is not configured.
final supabaseAuthServiceProvider = Provider<SupabaseAuthService?>((ref) {
  if (!AppConfig.hasSupabase) return null;
  return SupabaseAuthService(Supabase.instance.client);
});
