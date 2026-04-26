import '../../domain/entities/issue_comment_entity.dart';

class IssueCommentModel {
  final int id;
  final String authorLogin;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
  final String htmlUrl;

  const IssueCommentModel({
    required this.id,
    required this.authorLogin,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
    required this.htmlUrl,
  });

  factory IssueCommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return IssueCommentModel(
      id: json['id'] as int? ?? 0,
      authorLogin: user['login'] as String? ?? '',
      authorAvatarUrl: user['avatar_url'] as String?,
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }

  IssueCommentEntity toEntity() => IssueCommentEntity(
        id: id,
        authorLogin: authorLogin,
        authorAvatarUrl: authorAvatarUrl,
        body: body,
        createdAt: createdAt,
        htmlUrl: htmlUrl,
      );
}
