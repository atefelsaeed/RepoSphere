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
  });
}
