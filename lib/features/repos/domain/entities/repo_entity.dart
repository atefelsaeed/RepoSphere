import '../../../../core/git/git_provider_type.dart';

class RepoEntity {
  final int id;
  final String name;
  final String fullName;
  final String? description;
  final String htmlUrl;
  final String? language;
  final int stargazersCount;
  final int forksCount;
  final int watchersCount;
  final int openIssuesCount;
  final bool isPrivate;
  final bool isFork;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String ownerLogin;
  final String ownerAvatarUrl;
  final List<String> topics;
  final String? defaultBranch;
  final GitProviderType provider;

  /// Id of the [GitConnection] this repo was fetched through. Empty when not
  /// yet attributed (legacy single-account data) — resolved to the primary
  /// connection of [provider] at call sites.
  final String connectionId;

  /// Provider-native repo identifier when [id] (int) is insufficient — e.g.
  /// Azure DevOps repositories are keyed by GUID. Empty for GitHub/GitLab,
  /// which address repos by owner/name or numeric id.
  final String providerId;

  const RepoEntity({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    required this.htmlUrl,
    this.language,
    required this.stargazersCount,
    required this.forksCount,
    required this.watchersCount,
    required this.openIssuesCount,
    required this.isPrivate,
    required this.isFork,
    required this.updatedAt,
    required this.createdAt,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    required this.topics,
    this.defaultBranch,
    this.provider = GitProviderType.github,
    this.connectionId = '',
    this.providerId = '',
  });

  RepoEntity copyWith({
    GitProviderType? provider,
    String? connectionId,
    String? providerId,
  }) =>
      RepoEntity(
        id: id,
        name: name,
        fullName: fullName,
        description: description,
        htmlUrl: htmlUrl,
        language: language,
        stargazersCount: stargazersCount,
        forksCount: forksCount,
        watchersCount: watchersCount,
        openIssuesCount: openIssuesCount,
        isPrivate: isPrivate,
        isFork: isFork,
        updatedAt: updatedAt,
        createdAt: createdAt,
        ownerLogin: ownerLogin,
        ownerAvatarUrl: ownerAvatarUrl,
        topics: topics,
        defaultBranch: defaultBranch,
        provider: provider ?? this.provider,
        connectionId: connectionId ?? this.connectionId,
        providerId: providerId ?? this.providerId,
      );
}
