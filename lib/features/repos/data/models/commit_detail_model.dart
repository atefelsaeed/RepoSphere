import '../../domain/entities/commit_detail_entity.dart';

class CommitDetailModel {
  factory CommitDetailModel.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>;
    final commitAuthor = commit['author'] as Map<String, dynamic>;
    final author = json['author'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawFiles = json['files'] as List<dynamic>? ?? [];

    final files = rawFiles.map((f) {
      final fm = f as Map<String, dynamic>;
      return CommitFileChange(
        filename: fm['filename'] as String,
        status: fm['status'] as String? ?? 'modified',
        additions: fm['additions'] as int? ?? 0,
        deletions: fm['deletions'] as int? ?? 0,
        changes: fm['changes'] as int? ?? 0,
        patch: fm['patch'] as String?,
      );
    }).toList();

    return CommitDetailModel._(CommitDetailEntity(
      sha: json['sha'] as String,
      message: commit['message'] as String,
      authorName: commitAuthor['name'] as String,
      authorAvatarUrl: author?['avatar_url'] as String?,
      authorLogin: author?['login'] as String?,
      date: DateTime.parse(commitAuthor['date'] as String),
      htmlUrl: json['html_url'] as String,
      totalAdditions: stats['additions'] as int? ?? 0,
      totalDeletions: stats['deletions'] as int? ?? 0,
      files: files,
    ));
  }

  CommitDetailModel._(this.entity);
  final CommitDetailEntity entity;
}
