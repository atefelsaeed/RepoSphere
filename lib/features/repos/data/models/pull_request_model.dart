import '../../domain/entities/pull_request_entity.dart';

class PullRequestModel {
  final int number;
  final String title;
  final String state;
  final bool draft;
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

  const PullRequestModel({
    required this.number,
    required this.title,
    required this.state,
    required this.draft,
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

  factory PullRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final head = json['head'] as Map<String, dynamic>? ?? {};
    final base = json['base'] as Map<String, dynamic>? ?? {};
    final rawLabels = json['labels'] as List<dynamic>? ?? [];

    return PullRequestModel(
      number: json['number'] as int,
      title: json['title'] as String,
      state: json['state'] as String,
      draft: json['draft'] as bool? ?? false,
      body: json['body'] as String?,
      htmlUrl: json['html_url'] as String,
      authorLogin: user['login'] as String? ?? 'unknown',
      authorAvatarUrl: user['avatar_url'] as String?,
      headBranch: head['ref'] as String? ?? '',
      baseBranch: base['ref'] as String? ?? '',
      labels: rawLabels.map((l) {
        final lm = l as Map<String, dynamic>;
        return LabelEntity(
          name: lm['name'] as String,
          color: lm['color'] as String,
        );
      }).toList(),
      commentsCount: json['comments'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      mergedAt: json['merged_at'] != null
          ? DateTime.parse(json['merged_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  PullRequestEntity toEntity() {
    PrState prState;
    if (draft && state == 'open') {
      prState = PrState.draft;
    } else if (mergedAt != null) {
      prState = PrState.merged;
    } else if (state == 'closed') {
      prState = PrState.closed;
    } else {
      prState = PrState.open;
    }

    return PullRequestEntity(
      number: number,
      title: title,
      state: prState,
      body: body,
      htmlUrl: htmlUrl,
      authorLogin: authorLogin,
      authorAvatarUrl: authorAvatarUrl,
      headBranch: headBranch,
      baseBranch: baseBranch,
      labels: labels,
      commentsCount: commentsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      mergedAt: mergedAt,
      closedAt: closedAt,
    );
  }
}
