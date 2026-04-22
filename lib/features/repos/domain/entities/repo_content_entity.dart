enum ContentType { file, dir, symlink, submodule }

class RepoContentItem {
  final String name;
  final String path;
  final ContentType type;
  final int? size;
  final String? downloadUrl;
  final String sha;

  const RepoContentItem({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.downloadUrl,
    required this.sha,
  });

  bool get isDir => type == ContentType.dir;
}

class FileContent {
  final String path;
  final String content;
  final String encoding;

  const FileContent({
    required this.path,
    required this.content,
    required this.encoding,
  });
}
