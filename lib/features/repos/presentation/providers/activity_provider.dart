import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repos_provider.dart';
import '../../domain/entities/activity_event_entity.dart';

final activityProvider =
    FutureProvider.family<List<ActivityEventEntity>, String>(
        (ref, username) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getUserEvents(username);
  return models.map((m) => m.toEntity()).toList();
});
