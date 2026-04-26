enum PrState { open, closed, merged, draft }

class LabelEntity {
  final String name;
  final String color;
  const LabelEntity({required this.name, required this.color});
}

class PullRequestEntity {
  final int number;
  final String title;
  final PrState state;
  final String? body;
  final String htmlUrl;
  final String authorLogin;
  final String? authorAvatarUrl;
  final String headBranch;
  final String baseBranch;
  final List<LabelEntity> labels;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? mergedAt;
  final DateTime? closedAt;

  const PullRequestEntity({
    required this.number,
    required this.title,
    required this.state,
    this.body,
    required this.htmlUrl,
    required this.authorLogin,
    this.authorAvatarUrl,
    required this.headBranch,
    required this.baseBranch,
    required this.labels,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.mergedAt,
    this.closedAt,
  });
}
