/// The Git hosting provider a connection / repo belongs to.
///
/// Single source of truth shared by the auth (`GitConnection`) and repos
/// (`RepoEntity`) layers so there is exactly one provider enum in the app.
enum GitProviderType {
  github,
  gitlab,
  azureDevOps,
  bitbucket,
  gitea;

  /// Human-readable label for UI badges and pickers.
  String get label => switch (this) {
        GitProviderType.github => 'GitHub',
        GitProviderType.gitlab => 'GitLab',
        GitProviderType.azureDevOps => 'Azure DevOps',
        GitProviderType.bitbucket => 'Bitbucket',
        GitProviderType.gitea => 'Gitea',
      };

  /// Stable string id used in JSON persistence (never localise this).
  String get slug => name;

  static GitProviderType fromSlug(String slug) => GitProviderType.values
      .firstWhere((t) => t.name == slug, orElse: () => GitProviderType.github);

  /// Whether this provider needs a user-supplied base URL
  /// (self-hosted instances, or Azure DevOps organisation).
  bool get requiresBaseUrl =>
      this == GitProviderType.azureDevOps ||
      this == GitProviderType.gitea ||
      this == GitProviderType.bitbucket;
}
