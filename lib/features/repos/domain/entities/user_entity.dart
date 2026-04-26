class UserEntity {
  final String login;
  final String? name;
  final String avatarUrl;
  final String? bio;
  final String? location;
  final String? company;
  final String? email;
  final String? blog;
  final int publicRepos;
  final int followers;
  final int following;
  final DateTime? createdAt;

  const UserEntity({
    required this.login,
    this.name,
    required this.avatarUrl,
    this.bio,
    this.location,
    this.company,
    this.email,
    this.blog,
    required this.publicRepos,
    required this.followers,
    required this.following,
    this.createdAt,
  });
}
