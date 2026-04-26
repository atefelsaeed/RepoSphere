import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gist_entity.dart';
import 'repos_provider.dart';

final gistsProvider =
    FutureProvider<List<GistEntity>>((ref) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getGists();
  return models.map((m) => m.toEntity()).toList();
});
