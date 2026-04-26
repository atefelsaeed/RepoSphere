import '../../domain/entities/release_entity.dart';

class ReleaseModel {
  final int id;
  final String tagName;
  final String? name;
  final String? body;
  final DateTime publishedAt;
  final bool isDraft;
  final bool isPreRelease;
  final String htmlUrl;
  final String authorLogin;
  final String? authorAvatarUrl;

  const ReleaseModel({
    required this.id,
    required this.tagName,
    this.name,
    this.body,
    required this.publishedAt,
    required this.isDraft,
    required this.isPreRelease,
    required this.htmlUrl,
    required this.authorLogin,
    this.authorAvatarUrl,
  });

  factory ReleaseModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    return ReleaseModel(
      id: json['id'] as int? ?? 0,
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String?,
      body: json['body'] as String?,
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
              DateTime.now(),
      isDraft: json['draft'] as bool? ?? false,
      isPreRelease: json['prerelease'] as bool? ?? false,
      htmlUrl: json['html_url'] as String? ?? '',
      authorLogin: author['login'] as String? ?? '',
      authorAvatarUrl: author['avatar_url'] as String?,
    );
  }

  ReleaseEntity toEntity() => ReleaseEntity(
        id: id,
        tagName: tagName,
        name: name,
        body: body,
        publishedAt: publishedAt,
        isDraft: isDraft,
        isPreRelease: isPreRelease,
        htmlUrl: htmlUrl,
        authorLogin: authorLogin,
        authorAvatarUrl: authorAvatarUrl,
      );
}
