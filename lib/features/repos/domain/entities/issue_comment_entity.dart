class IssueCommentEntity {
  final int id;
  final String authorLogin;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
  final String htmlUrl;

  const IssueCommentEntity({
    required this.id,
    required this.authorLogin,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
    required this.htmlUrl,
  });
}
