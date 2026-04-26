class ContributorEntity {
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final int contributions;

  const ContributorEntity({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.contributions,
  });
}
