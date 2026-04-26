/// Runtime configuration — fill in your own credentials before running.
///
/// GitHub OAuth App: github.com/settings/developers → OAuth Apps → New
///   Homepage URL: your web app URL
///   Authorization callback URL: http://localhost  (not used for device flow)
///   Copy the Client ID below. No client secret needed for device flow.
///
/// Supabase (Phase 2.5): supabase.com → New project → Settings → API
class AppConfig {
  static const githubClientId = '';

  // Phase 2.5 — leave empty until Supabase project is created
  static const supabaseUrl = '';
  static const supabaseAnonKey = '';

  static bool get hasGitHubOAuth => githubClientId.isNotEmpty;
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
