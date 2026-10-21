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

/// Splits a multi-file `git diff` (as served by Gitea/Forgejo `.diff`) into
/// per-file [DiffFile]s with status, line counts and the hunks as the patch.
List<DiffFile> parseGitDiff(String diff) {
  final files = <DiffFile>[];
  final blocks = diff.split(RegExp(r'^diff --git ', multiLine: true));
  for (final block in blocks) {
    if (block.trim().isEmpty) continue;
    final lines = block.split('\n');
    // First line: "a/old/path b/new/path"
    final header = RegExp(r'^a/(.+?) b/(.+)$').firstMatch(lines.first);
    var path = header?.group(2) ?? lines.first;
    var status = 'modified';
    var firstHunk = -1;
    for (var i = 1; i < lines.length; i++) {
      final l = lines[i];
      if (l.startsWith('new file mode')) status = 'added';
      if (l.startsWith('deleted file mode')) status = 'removed';
      if (l.startsWith('rename to ')) {
        status = 'renamed';
        path = l.substring('rename to '.length);
      }
      if (l.startsWith('@@')) {
        firstHunk = i;
        break;
      }
    }
    final patch =
        firstHunk < 0 ? null : lines.sublist(firstHunk).join('\n').trimRight();
    final c = countDiff(patch);
    files.add(DiffFile(
      path: path,
      status: status,
      additions: c.additions,
      deletions: c.deletions,
      patch: patch,
    ));
  }
  return files;
}
