import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/issue_comment_entity.dart';
import 'repos_provider.dart';

final issueCommentsProvider = FutureProvider.family<List<IssueCommentEntity>,
    ({String owner, String repo, int number})>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models =
      await ds.getIssueComments(args.owner, args.repo, args.number);
  return models.map((m) => m.toEntity()).toList();
});
