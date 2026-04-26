import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/release_entity.dart';
import 'repos_provider.dart';

final repoReleasesProvider = FutureProvider.family<List<ReleaseEntity>,
    ({String owner, String repo})>((ref, args) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getReleases(args.owner, args.repo);
  return models.map((m) => m.toEntity()).toList();
});
