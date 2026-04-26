import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repos_provider.dart';
import '../../domain/entities/contributor_entity.dart';

final repoContributorsProvider = FutureProvider.family<List<ContributorEntity>,
    ({String owner, String repo})>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getContributors(args.owner, args.repo);
  return models.map((m) => m.toEntity()).toList();
});
