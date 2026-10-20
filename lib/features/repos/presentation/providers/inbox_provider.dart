import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/git_provider_factory.dart';
import '../../domain/entities/inbox_item_entity.dart';

/// Snapshot of the inbox across all accounts.
class InboxResult {
  final List<InboxItem> items;

  /// Per-account failures, keyed by the account's display name.
  final Map<String, Object> errors;

  /// True while showing the last saved snapshot, before the refresh lands.
  final bool fromCache;

  const InboxResult({
    this.items = const [],
    this.errors = const {},
    this.fromCache = false,
  });
}

const _cacheKey = 'inbox_cache_v1';

/// Everything that needs the user's attention across all connected accounts,
/// most urgent first. Emits the cached snapshot immediately (if any), then the
/// fresh result. A failing account is reported in [InboxResult.errors] instead
/// of failing the whole inbox.
final inboxProvider = StreamProvider<InboxResult>((ref) async* {
  final providers = ref
      .watch(activeProvidersProvider)
      .where((p) => p.capabilities.inbox)
      .toList();
  final liveIds = providers.map((p) => p.connection.id).toSet();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      final cached = (jsonDecode(raw) as List)
          .map((e) => InboxItem.fromJson(e as Map<String, dynamic>))
          .where((i) => liveIds.contains(i.connectionId))
          .toList();
      if (cached.isNotEmpty) {
        yield InboxResult(items: cached, fromCache: true);
      }
    }
  } on Object {
    // Corrupt or unavailable cache is never fatal.
  }

  final errors = <String, Object>{};
  final results = await Future.wait(providers.map((p) async {
    try {
      return await p.getInboxItems();
    } on Exception catch (e) {
      errors[p.connection.displayName] = e;
      return const <InboxItem>[];
    }
  }));
  final items = InboxItem.mergeAndSort(results.expand((e) => e));

  // Keep the old snapshot if everything failed, so offline still shows data.
  if (errors.length < providers.length || providers.isEmpty) {
    try {
      await prefs?.setString(
          _cacheKey, jsonEncode(items.map((i) => i.toJson()).toList()));
    } on Object {
      // ignore
    }
  }
  yield InboxResult(items: items, errors: errors);
});

// ─── Filters ──────────────────────────────────────────────────────────────────
/// Optional account filter (null = all accounts).
final inboxConnectionFilterProvider = StateProvider<String?>((ref) => null);

/// Optional reason filter (null = every reason).
final inboxReasonFilterProvider = StateProvider<InboxReason?>((ref) => null);

// ─── Done / snoozed ───────────────────────────────────────────────────────────
class InboxDismissal {
  final DateTime? snoozedUntil;
  final DateTime? doneAt;
  const InboxDismissal({this.snoozedUntil, this.doneAt});

  Map<String, dynamic> toJson() => {
        if (snoozedUntil != null) 'u': snoozedUntil!.toIso8601String(),
        if (doneAt != null) 'd': doneAt!.toIso8601String(),
      };

  static InboxDismissal fromJson(Map<String, dynamic> j) => InboxDismissal(
        snoozedUntil:
            j['u'] == null ? null : DateTime.parse(j['u'] as String),
        doneAt: j['d'] == null ? null : DateTime.parse(j['d'] as String),
      );
}

/// Tracks items the user marked done or snoozed. A "done" item comes back
/// only if it has new activity after it was dismissed.
class InboxDismissals extends StateNotifier<Map<String, InboxDismissal>> {
  static const _key = 'inbox_dismissals_v1';

  InboxDismissals() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final now = DateTime.now();
      final map = (jsonDecode(raw) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, InboxDismissal.fromJson(v as Map<String, dynamic>)));
      // Drop expired snoozes with no "done" marker.
      map.removeWhere((_, d) =>
          d.doneAt == null &&
          d.snoozedUntil != null &&
          d.snoozedUntil!.isBefore(now));
      state = map;
    } on Object {
      // ignore corrupt state
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((k, v) => MapEntry(k, v.toJson()))));
    } on Object {
      // ignore
    }
  }

  void markDone(InboxItem item) {
    state = {...state, item.key: InboxDismissal(doneAt: DateTime.now())};
    _save();
  }

  void snooze(InboxItem item, Duration d) {
    state = {
      ...state,
      item.key: InboxDismissal(snoozedUntil: DateTime.now().add(d)),
    };
    _save();
  }

  void restore(InboxItem item) {
    state = {...state}..remove(item.key);
    _save();
  }

  bool isHidden(InboxItem item, DateTime now) {
    final d = state[item.key];
    if (d == null) return false;
    if (d.snoozedUntil != null && now.isBefore(d.snoozedUntil!)) return true;
    if (d.doneAt != null && !item.updatedAt.isAfter(d.doneAt!)) return true;
    return false;
  }
}

final inboxDismissalsProvider =
    StateNotifierProvider<InboxDismissals, Map<String, InboxDismissal>>(
        (ref) => InboxDismissals());

/// Items visible after dismissals, before account/reason filters. Used for the
/// filter chips' counts and the badge.
final visibleInboxProvider = Provider<AsyncValue<InboxResult>>((ref) {
  final dismissals = ref.watch(inboxDismissalsProvider.notifier);
  ref.watch(inboxDismissalsProvider); // rebuild on change
  final now = DateTime.now();
  return ref.watch(inboxProvider).whenData((r) => InboxResult(
        items: r.items.where((i) => !dismissals.isHidden(i, now)).toList(),
        errors: r.errors,
        fromCache: r.fromCache,
      ));
});

/// [visibleInboxProvider] narrowed by the account and reason filters.
final filteredInboxProvider = Provider<AsyncValue<InboxResult>>((ref) {
  final conn = ref.watch(inboxConnectionFilterProvider);
  final reason = ref.watch(inboxReasonFilterProvider);
  return ref.watch(visibleInboxProvider).whenData((r) => InboxResult(
        items: r.items
            .where((i) =>
                (conn == null || i.connectionId == conn) &&
                (reason == null || i.reasons.contains(reason)))
            .toList(),
        errors: r.errors,
        fromCache: r.fromCache,
      ));
});

// ─── Quick actions ────────────────────────────────────────────────────────────
/// Runs a PR action through the owning account, then refreshes the inbox.
Future<void> runInboxAction(
  WidgetRef ref,
  InboxItem item,
  PrAction action, {
  String? comment,
}) async {
  final provider = ref.read(providerForConnectionProvider(item.connectionId));
  if (provider == null) {
    throw StateError('That account is no longer connected.');
  }
  await provider.performPrAction(item, action, comment: comment);
  ref.invalidate(inboxProvider);
}
