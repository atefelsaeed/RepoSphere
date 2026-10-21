import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/inbox_item_entity.dart';
import '../domain/repositories/git_provider.dart';

/// Items gathered from every account plus per-account failures.
class InboxLoad {
  final List<InboxItem> items;

  /// Keyed by the account's display name.
  final Map<String, Object> errors;

  /// How many accounts were asked.
  final int attempted;
  const InboxLoad(this.items, this.errors, this.attempted);

  /// True when there was something to load and every account failed.
  bool get allFailed => attempted > 0 && errors.length == attempted;
}

/// Loads the inbox from [providers] concurrently. A failing account is
/// reported in [InboxLoad.errors] instead of failing the whole load.
/// Shared by the UI provider and the background check.
Future<InboxLoad> loadInbox(Iterable<GitProvider> providers) async {
  final list = providers.where((p) => p.capabilities.inbox).toList();
  final errors = <String, Object>{};
  final results = await Future.wait(list.map((p) async {
    try {
      return await p.getInboxItems();
    } on Exception catch (e) {
      errors[p.connection.displayName] = e;
      return const <InboxItem>[];
    }
  }));
  return InboxLoad(
      InboxItem.mergeAndSort(results.expand((e) => e)), errors, list.length);
}

/// Last successful inbox snapshot, so the app opens instantly.
class InboxCache {
  static const _key = 'inbox_cache_v1';

  static List<InboxItem> read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => InboxItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return const [];
    }
  }

  static Future<void> write(
          SharedPreferences prefs, List<InboxItem> items) =>
      prefs.setString(_key, jsonEncode(items.map((i) => i.toJson()).toList()));
}
