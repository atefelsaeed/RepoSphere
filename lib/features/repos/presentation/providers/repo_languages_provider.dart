import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repos_provider.dart';

final repoLanguagesProvider = FutureProvider.family<Map<String, int>,
    ({String owner, String repo})>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return {};
  return ds.getLanguages(args.owner, args.repo);
});
