import '../../domain/entities/user_entity.dart';

class UserModel {
  final String login;
  final String? name;
  final String avatarUrl;
  final String? bio;
  final int publicRepos;
  final int followers;
  final int following;

  const UserModel({
    required this.login,
    this.name,
    required this.avatarUrl,
    this.bio,
    required this.publicRepos,
    required this.followers,
    required this.following,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        login: json['login'] as String,
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String,
        bio: json['bio'] as String?,
        publicRepos: json['public_repos'] as int? ?? 0,
        followers: json['followers'] as int? ?? 0,
        following: json['following'] as int? ?? 0,
      );

  UserEntity toEntity() => UserEntity(
        login: login,
        name: name,
        avatarUrl: avatarUrl,
        bio: bio,
        publicRepos: publicRepos,
        followers: followers,
        following: following,
      );
}
