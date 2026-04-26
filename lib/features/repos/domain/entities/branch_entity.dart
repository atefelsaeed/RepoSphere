class BranchEntity {
  final String name;
  final String sha;
  final bool isProtected;

  const BranchEntity({
    required this.name,
    required this.sha,
    required this.isProtected,
  });
}
