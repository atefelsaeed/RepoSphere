class GistFile {
  final String name;
  final String? language;
  final int size;
  final String rawUrl;

  const GistFile({
    required this.name,
    required this.size,
    this.language,
    required this.rawUrl,
  });
}

class GistEntity {
  final String id;
  final String? description;
  final bool isPublic;
  final List<GistFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String htmlUrl;
  final int commentsCount;

  const GistEntity({
    required this.id,
    this.description,
    required this.isPublic,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    required this.htmlUrl,
    required this.commentsCount,
  });

  String get displayTitle {
    if (description != null && description!.trim().isNotEmpty) {
      return description!;
    }
    return files.isNotEmpty ? files.first.name : id.substring(0, 8);
  }
}
