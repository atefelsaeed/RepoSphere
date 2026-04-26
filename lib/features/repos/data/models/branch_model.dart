import '../../domain/entities/branch_entity.dart';

class BranchModel {
  final String name;
  final String sha;
  final bool isProtected;

  const BranchModel({
    required this.name,
    required this.sha,
    required this.isProtected,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>;
    return BranchModel(
      name: json['name'] as String,
      sha: commit['sha'] as String,
      isProtected: json['protected'] as bool? ?? false,
    );
  }

  BranchEntity toEntity() => BranchEntity(
        name: name,
        sha: sha,
        isProtected: isProtected,
      );
}
