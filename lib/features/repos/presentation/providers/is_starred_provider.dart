import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repos_provider.dart';

final isStarredProvider = FutureProvider.family<bool,
    ({String owner, String repo})>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return false;
  return ds.isStarred(args.owner, args.repo);
});
