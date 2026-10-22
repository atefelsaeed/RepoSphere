import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repos_provider.dart';

final isStarredProvider = FutureProvider.family<bool,
    ({String owner, String repo, String connectionId})>((ref, args) async {
  final ds = ref.watch(githubDatasourceForConnectionProvider(args.connectionId));
  if (ds == null) return false;
  return ds.isStarred(args.owner, args.repo);
});
