import '../../domain/entities/gist_entity.dart';

class GistModel {
  final String id;
  final String? description;
  final bool isPublic;
  final List<GistFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String htmlUrl;
  final int commentsCount;

  const GistModel({
    required this.id,
    this.description,
    required this.isPublic,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    required this.htmlUrl,
    required this.commentsCount,
  });

  factory GistModel.fromJson(Map<String, dynamic> json) {
    final filesMap = json['files'] as Map<String, dynamic>? ?? {};
    final files = filesMap.entries.map((e) {
      final f = e.value as Map<String, dynamic>;
      return GistFile(
        name: f['filename'] as String? ?? e.key,
        language: f['language'] as String?,
        size: f['size'] as int? ?? 0,
        rawUrl: f['raw_url'] as String? ?? '',
      );
    }).toList();

    return GistModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String?,
      isPublic: json['public'] as bool? ?? true,
      files: files,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
              DateTime.now(),
      htmlUrl: json['html_url'] as String? ?? '',
      commentsCount: json['comments'] as int? ?? 0,
    );
  }

  GistEntity toEntity() => GistEntity(
        id: id,
        description: description,
        isPublic: isPublic,
        files: files,
        createdAt: createdAt,
        updatedAt: updatedAt,
        htmlUrl: htmlUrl,
        commentsCount: commentsCount,
      );
}
