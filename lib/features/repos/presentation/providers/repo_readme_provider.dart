import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repos_provider.dart';

typedef _ReadmeArgs = ({String owner, String repo});

final repoReadmeProvider =
    FutureProvider.family<String?, _ReadmeArgs>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return null;
  return ds.getReadme(args.owner, args.repo);
});
