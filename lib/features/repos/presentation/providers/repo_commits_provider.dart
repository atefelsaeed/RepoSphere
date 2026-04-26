import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/commit_entity.dart';
import 'repos_provider.dart';

typedef _CommitsArgs = ({String owner, String repo});

final repoCommitsProvider =
    FutureProvider.family<List<CommitEntity>, _CommitsArgs>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getCommits(args.owner, args.repo);
  return models.map((m) => m.toEntity()).toList();
});
