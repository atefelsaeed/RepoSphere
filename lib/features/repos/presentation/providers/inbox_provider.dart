import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/git_provider_factory.dart';
import '../../domain/entities/inbox_item_entity.dart';

/// Optional account filter for the inbox (null = all accounts).
final inboxConnectionFilterProvider = StateProvider<String?>((ref) => null);

/// Everything that needs the user's attention across all connected accounts,
/// most urgent first. A provider that fails is skipped, not fatal.
final inboxProvider = FutureProvider<List<InboxItem>>((ref) async {
  final providers = ref
      .watch(activeProvidersProvider)
      .where((p) => p.capabilities.inbox)
      .toList();
  final results = await Future.wait(providers.map((p) async {
    try {
      return await p.getInboxItems();
    } on Exception {
      return const <InboxItem>[];
    }
  }));
  return InboxItem.mergeAndSort(results.expand((e) => e));
});

/// [inboxProvider] narrowed by [inboxConnectionFilterProvider].
final filteredInboxProvider = Provider<AsyncValue<List<InboxItem>>>((ref) {
  final filter = ref.watch(inboxConnectionFilterProvider);
  return ref.watch(inboxProvider).whenData((items) => filter == null
      ? items
      : items.where((i) => i.connectionId == filter).toList());
});
