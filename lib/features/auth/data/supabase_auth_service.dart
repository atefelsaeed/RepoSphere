import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client;

  const SupabaseAuthService(this._client);

  /// Returns the GitHub OAuth token from the current Supabase session,
  /// or null if no session exists.
  String? get currentGitHubToken =>
      _client.auth.currentSession?.providerToken;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Starts GitHub OAuth via Supabase.
  /// On web: redirects the browser (no redirectTo needed).
  /// On mobile: requires a deep-link redirectTo like 'io.reposphere://login'.
  Future<void> signInWithGitHub({String? redirectTo}) async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: redirectTo,
      scopes: 'repo read:user notifications gist',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
