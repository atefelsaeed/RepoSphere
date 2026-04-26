import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/repo_entity.dart';
import 'repos_provider.dart';

final globalSearchProvider =
    FutureProvider.family<List<RepoEntity>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.searchRepos(query.trim());
  return models.map((m) => m.toEntity()).toList();
});
