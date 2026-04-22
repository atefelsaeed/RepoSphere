import '../../domain/entities/repo_entity.dart';

class RepoModel {
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

  const RepoModel({
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
  });

  factory RepoModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>;
    return RepoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
      htmlUrl: json['html_url'] as String,
      language: json['language'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      watchersCount: json['watchers_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      isPrivate: json['private'] as bool? ?? false,
      isFork: json['fork'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerLogin: owner['login'] as String,
      ownerAvatarUrl: owner['avatar_url'] as String,
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
      );
}
