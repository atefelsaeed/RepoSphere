import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import 'repos_provider.dart';

final notificationsProvider =
    FutureProvider<List<NotificationEntity>>((ref) async {
  final ds = ref.watch(githubDatasourceProvider);
  if (ds == null) return [];
  final models = await ds.getNotifications();
  return models.map((m) => m.toEntity()).toList();
});
