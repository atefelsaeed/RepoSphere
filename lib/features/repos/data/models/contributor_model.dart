import '../../domain/entities/contributor_entity.dart';

class ContributorModel {
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final int contributions;

  const ContributorModel({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.contributions,
  });

  factory ContributorModel.fromJson(Map<String, dynamic> json) =>
      ContributorModel(
        login: json['login'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        htmlUrl: json['html_url'] as String? ?? '',
        contributions: json['contributions'] as int? ?? 0,
      );

  ContributorEntity toEntity() => ContributorEntity(
        login: login,
        avatarUrl: avatarUrl,
        htmlUrl: htmlUrl,
        contributions: contributions,
      );
}
