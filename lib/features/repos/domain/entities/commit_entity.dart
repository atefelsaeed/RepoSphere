class CommitEntity {
  final String sha;
  final String message;
  final String authorName;
  final String? authorAvatarUrl;
  final String? authorLogin;
  final DateTime date;
  final String htmlUrl;

  const CommitEntity({
    required this.sha,
    required this.message,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorLogin,
    required this.date,
    required this.htmlUrl,
  });

  String get shortSha => sha.substring(0, 7);
  String get firstLine => message.split('\n').first.trim();
}
