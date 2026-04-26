import 'pull_request_entity.dart';

enum IssueState { open, closed }

class IssueEntity {
  final int number;
  final String title;
  final IssueState state;
  final String? body;
  final String htmlUrl;
  final String authorLogin;
  final String? authorAvatarUrl;
  final List<LabelEntity> labels;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  const IssueEntity({
    required this.number,
    required this.title,
    required this.state,
    this.body,
    required this.htmlUrl,
    required this.authorLogin,
    this.authorAvatarUrl,
    required this.labels,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });
}
