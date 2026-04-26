import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/branch_entity.dart';
import 'repos_provider.dart';

typedef _BranchArgs = ({String owner, String repo});

final repoBranchesProvider =
    FutureProvider.family<List<BranchEntity>, _BranchArgs>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getBranches(args.owner, args.repo);
  return models.map((m) => m.toEntity()).toList();
});
