import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/pull_request_entity.dart';

class IssueModel {
  final int number;
  final String title;
  final String state;
  final String? body;
  final String htmlUrl;
  final String authorLogin;
  final String? authorAvatarUrl;
  final List<LabelEntity> labels;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  const IssueModel({
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

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final rawLabels = json['labels'] as List<dynamic>? ?? [];

    return IssueModel(
      number: json['number'] as int,
      title: json['title'] as String,
      state: json['state'] as String,
      body: json['body'] as String?,
      htmlUrl: json['html_url'] as String,
      authorLogin: user['login'] as String? ?? 'unknown',
      authorAvatarUrl: user['avatar_url'] as String?,
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
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  IssueEntity toEntity() => IssueEntity(
        number: number,
        title: title,
        state: state == 'open' ? IssueState.open : IssueState.closed,
        body: body,
        htmlUrl: htmlUrl,
        authorLogin: authorLogin,
        authorAvatarUrl: authorAvatarUrl,
        labels: labels,
        commentsCount: commentsCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        closedAt: closedAt,
      );
}
