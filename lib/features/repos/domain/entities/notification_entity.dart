class NotificationEntity {
  final String id;
  final String title;
  final String subjectType;
  final String repoFullName;
  final String reason;
  final bool unread;
  final DateTime updatedAt;
  final String htmlUrl;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.subjectType,
    required this.repoFullName,
    required this.reason,
    required this.unread,
    required this.updatedAt,
    required this.htmlUrl,
  });
}
