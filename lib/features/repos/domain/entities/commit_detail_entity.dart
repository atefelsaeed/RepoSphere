class CommitFileChange {
  final String filename;
  final String status;
  final int additions;
  final int deletions;
  final int changes;
  final String? patch;

  const CommitFileChange({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
    this.patch,
  });

  String get shortName => filename.split('/').last;
}

class CommitDetailEntity {
  final String sha;
  final String message;
  final String authorName;
  final String? authorAvatarUrl;
  final String? authorLogin;
  final DateTime date;
  final String htmlUrl;
  final int totalAdditions;
  final int totalDeletions;
  final List<CommitFileChange> files;

  const CommitDetailEntity({
    required this.sha,
    required this.message,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorLogin,
    required this.date,
    required this.htmlUrl,
    required this.totalAdditions,
    required this.totalDeletions,
    required this.files,
  });

  String get shortSha => sha.substring(0, 7);
  String get firstLine => message.split('\n').first.trim();
  String get bodyText {
    final parts = message.split('\n');
    if (parts.length <= 1) return '';
    return parts.skip(1).join('\n').trim();
  }
}
