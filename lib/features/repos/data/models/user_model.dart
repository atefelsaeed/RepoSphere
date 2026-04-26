import '../../domain/entities/user_entity.dart';

class UserModel {
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

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        login: json['login'] as String,
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String,
        bio: json['bio'] as String?,
        location: json['location'] as String?,
        company: json['company'] as String?,
        email: json['email'] as String?,
        blog: json['blog'] as String?,
        publicRepos: json['public_repos'] as int? ?? 0,
        followers: json['followers'] as int? ?? 0,
        following: json['following'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  UserEntity toEntity() => UserEntity(
        login: login,
        name: name,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        company: company,
        email: email,
        blog: blog,
        publicRepos: publicRepos,
        followers: followers,
        following: following,
        createdAt: createdAt,
      );
}
