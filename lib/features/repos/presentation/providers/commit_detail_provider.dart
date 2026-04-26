import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/commit_detail_entity.dart';
import 'repos_provider.dart';

final commitDetailProvider = FutureProvider.family<CommitDetailEntity,
    ({String owner, String repo, String sha})>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) throw Exception('Not authenticated');
  return ds.getCommitDetail(args.owner, args.repo, args.sha);
});
