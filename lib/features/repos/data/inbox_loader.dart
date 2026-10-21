import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/exceptions.dart';
import '../domain/entities/inbox_item_entity.dart';
import '../domain/repositories/git_provider.dart';

/// Items gathered from every account plus per-account failures.
class InboxLoad {
  final List<InboxItem> items;

  /// Accounts that could not be loaded at all, keyed by display name.
  final Map<String, Object> errors;

  /// Accounts that loaded but with some queries failing (results may be
  /// incomplete), keyed by display name.
  final Map<String, Object> partial;

  /// How many accounts were asked.
  final int attempted;
  const InboxLoad(this.items, this.errors, this.attempted,
      [this.partial = const {}]);

  /// True when there was something to load and every account failed.
  bool get allFailed => attempted > 0 && errors.length == attempted;
}

/// Loads the inbox from [providers] concurrently. A failing account is
/// reported in [InboxLoad.errors] instead of failing the whole load.
/// Shared by the UI provider and the background check.
Future<InboxLoad> loadInbox(Iterable<GitProvider> providers) async {
  final list = providers.where((p) => p.capabilities.inbox).toList();
  final errors = <String, Object>{};
  final partial = <String, Object>{};
  final results = await Future.wait(list.map((p) async {
    try {
      final batch = await p.getInboxItems();
      if (batch.isPartial) {
        partial[p.connection.displayName] = batch.failures.first;
      }
      return batch.items;
    } on Exception catch (e) {
      errors[p.connection.displayName] = e;
      return const <InboxItem>[];
    }
  }));
  return InboxLoad(InboxItem.mergeAndSort(results.expand((e) => e)), errors,
      list.length, partial);
}

/// Short, user-facing reason for an inbox failure.
String inboxErrorText(Object e,
    {String fallback = 'Network error or unexpected response.'}) {
  if (e is GitHubAuthException) return e.message;
  if (e is GitHubRateLimitException) return e.message;
  if (e is GitHubApiException) return e.message;
  return fallback;
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

  static Future<void> write(SharedPreferences prefs, List<InboxItem> items) =>
      prefs.setString(_key, jsonEncode(items.map((i) => i.toJson()).toList()));
}
