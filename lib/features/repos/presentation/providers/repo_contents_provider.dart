import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/repo_content_entity.dart';
import 'repos_provider.dart';

typedef _ContentsArgs = ({String owner, String repo, String path});
typedef _FileArgs = ({String owner, String repo, String path});

final repoContentsProvider =
    FutureProvider.family<List<RepoContentItem>, _ContentsArgs>((ref, args) {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return Future.value([]);
  return ds.getContents(args.owner, args.repo, args.path);
});

final fileContentProvider =
    FutureProvider.family<FileContent, _FileArgs>((ref, args) {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) throw StateError('Not authenticated');
  return ds.getFileContent(args.owner, args.repo, args.path);
});
