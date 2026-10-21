/// One changed file of a pull/merge request.
class DiffFile {
  final String path;

  /// `added`, `modified`, `removed` or `renamed`.
  final String status;
  final int additions;
  final int deletions;

  /// Unified diff body; null when the provider omitted it (binary / too big).
  final String? patch;

  const DiffFile({
    required this.path,
    required this.status,
    required this.additions,
    required this.deletions,
    this.patch,
  });
}

class DetailComment {
  final String authorLogin;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;

  const DetailComment({
    required this.authorLogin,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
  });
}

/// Read-only detail of an inbox PR/MR or issue, normalised across providers.
class ItemDetail {
  final String title;
  final String body;
  final String authorLogin;
  final String? authorAvatarUrl;

  /// `open`, `closed`, `merged` or `draft`.
  final String state;
  final DateTime createdAt;
  final String? headBranch;
  final String? baseBranch;
  final List<DiffFile> files;
  final List<DetailComment> comments;

  const ItemDetail({
    required this.title,
    required this.body,
    required this.authorLogin,
    this.authorAvatarUrl,
    required this.state,
    required this.createdAt,
    this.headBranch,
    this.baseBranch,
    this.files = const [],
    this.comments = const [],
  });

  int get additions => files.fold(0, (a, f) => a + f.additions);
  int get deletions => files.fold(0, (a, f) => a + f.deletions);
}

/// How a unified-diff line should be drawn.
enum DiffLineKind { added, removed, hunk, context }

DiffLineKind classifyDiffLine(String line) {
  if (line.startsWith('@@')) return DiffLineKind.hunk;
  if (line.startsWith('+') && !line.startsWith('+++')) return DiffLineKind.added;
  if (line.startsWith('-') && !line.startsWith('---')) {
    return DiffLineKind.removed;
  }
  return DiffLineKind.context;
}

/// Counts added/removed lines of a unified diff body.
({int additions, int deletions}) countDiff(String? patch) {
  var a = 0, d = 0;
  for (final line in (patch ?? '').split('\n')) {
    switch (classifyDiffLine(line)) {
      case DiffLineKind.added:
        a++;
      case DiffLineKind.removed:
        d++;
      default:
    }
  }
  return (additions: a, deletions: d);
}
