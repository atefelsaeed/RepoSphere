import '../../domain/entities/commit_entity.dart';

class CommitModel {
  final String sha;
  final String message;
  final String authorName;
  final String? authorAvatarUrl;
  final String? authorLogin;
  final DateTime date;
  final String htmlUrl;

  const CommitModel({
    required this.sha,
    required this.message,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorLogin,
    required this.date,
    required this.htmlUrl,
  });

  factory CommitModel.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>;
    final commitAuthor = commit['author'] as Map<String, dynamic>;
    final author = json['author'] as Map<String, dynamic>?;

    return CommitModel(
      sha: json['sha'] as String,
      message: commit['message'] as String,
      authorName: commitAuthor['name'] as String,
      authorAvatarUrl: author?['avatar_url'] as String?,
      authorLogin: author?['login'] as String?,
      date: DateTime.parse(commitAuthor['date'] as String),
      htmlUrl: json['html_url'] as String,
    );
  }

  CommitEntity toEntity() => CommitEntity(
        sha: sha,
        message: message,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorLogin: authorLogin,
        date: date,
        htmlUrl: htmlUrl,
      );
}
