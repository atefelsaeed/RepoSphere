import '../../../../core/git/git_provider_type.dart';
import '../../domain/entities/repo_entity.dart';

class GitLabProjectModel {
  final int id;
  final String name;
  final String pathWithNamespace;
  final String? description;
  final String webUrl;
  final String? language;
  final int starCount;
  final int forksCount;
  final int openIssuesCount;
  final String visibility;
  final bool forked;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final String ownerLogin;
  final String ownerAvatarUrl;
  final List<String> topics;
  final String? defaultBranch;

  const GitLabProjectModel({
    required this.id,
    required this.name,
    required this.pathWithNamespace,
    this.description,
    required this.webUrl,
    this.language,
    required this.starCount,
    required this.forksCount,
    required this.openIssuesCount,
    required this.visibility,
    required this.forked,
    required this.lastActivityAt,
    required this.createdAt,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    required this.topics,
    this.defaultBranch,
  });

  factory GitLabProjectModel.fromJson(Map<String, dynamic> json) {
    final ns = json['namespace'] as Map<String, dynamic>? ?? {};
    final rawAvatar = (json['avatar_url'] ?? ns['avatar_url']) as String?;
    final ownerPath = ns['path'] as String? ?? '';
    final avatarUrl = rawAvatar?.isNotEmpty == true
        ? rawAvatar!
        : 'https://gitlab.com/uploads/-/system/group/avatar/placeholder.png';

    return GitLabProjectModel(
      id: json['id'] as int,
      name: json['name'] as String,
      pathWithNamespace: json['path_with_namespace'] as String,
      description: json['description'] as String?,
      webUrl: json['web_url'] as String,
      language: null, // GitLab /projects doesn't return primary language
      starCount: json['star_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      visibility: json['visibility'] as String? ?? 'private',
      forked: json['forked_from_project'] != null,
      lastActivityAt:
          DateTime.parse(json['last_activity_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerLogin: ownerPath,
      ownerAvatarUrl: avatarUrl,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
      defaultBranch: json['default_branch'] as String?,
    );
  }

  RepoEntity toEntity() => RepoEntity(
        id: id,
        name: name,
        fullName: pathWithNamespace,
        description: description,
        htmlUrl: webUrl,
        language: language,
        stargazersCount: starCount,
        forksCount: forksCount,
        watchersCount: 0,
        openIssuesCount: openIssuesCount,
        isPrivate: visibility == 'private',
        isFork: forked,
        updatedAt: lastActivityAt,
        createdAt: createdAt,
        ownerLogin: ownerLogin,
        ownerAvatarUrl: ownerAvatarUrl,
        topics: topics,
        defaultBranch: defaultBranch,
        provider: GitProviderType.gitlab,
      );
}
