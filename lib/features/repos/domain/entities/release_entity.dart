class ReleaseEntity {
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

  const ReleaseEntity({
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

  String get displayName => name?.isNotEmpty == true ? name! : tagName;
}
