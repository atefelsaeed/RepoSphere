class ActivityEventEntity {
  final String id;
  final String type;
  final String actorLogin;
  final String? actorAvatarUrl;
  final String repoName;
  final DateTime createdAt;
  final String summary;

  const ActivityEventEntity({
    required this.id,
    required this.type,
    required this.actorLogin,
    this.actorAvatarUrl,
    required this.repoName,
    required this.createdAt,
    required this.summary,
  });
}
