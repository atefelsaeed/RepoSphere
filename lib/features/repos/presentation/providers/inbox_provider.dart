import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/git_provider_factory.dart';
import '../../data/inbox_dismissal_store.dart';
import '../../data/inbox_loader.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/workspace_entity.dart';
import 'workspaces_provider.dart';

/// Snapshot of the inbox across all accounts.
class InboxResult {
  final List<InboxItem> items;

  /// Per-account failures, keyed by the account's display name.
  final Map<String, Object> errors;

  /// Accounts that loaded with some queries failing, keyed by display name.
  final Map<String, Object> partial;

  /// True while showing the last saved snapshot, before the refresh lands.
  final bool fromCache;

  const InboxResult({
    this.items = const [],
    this.errors = const {},
    this.partial = const {},
    this.fromCache = false,
  });
}

/// Everything that needs the user's attention across all connected accounts,
/// most urgent first. Emits the cached snapshot immediately (if any), then the
/// fresh result. A failing account is reported in [InboxResult.errors] instead
/// of failing the whole inbox.
final inboxProvider = StreamProvider<InboxResult>((ref) async* {
  final providers = ref.watch(activeProvidersProvider);
  final liveIds = providers.map((p) => p.connection.id).toSet();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    final cached =
        InboxCache.read(prefs).where((i) => liveIds.contains(i.connectionId)).toList();
    if (cached.isNotEmpty) yield InboxResult(items: cached, fromCache: true);
  } on Object {
    // Unavailable cache is never fatal.
  }

  final load = await loadInbox(providers);

  // Keep the old snapshot if everything failed, so offline still shows data.
  if (!load.allFailed) {
    try {
      if (prefs != null) await InboxCache.write(prefs, load.items);
    } on Object {
      // ignore
    }
  }
  yield InboxResult(
      items: load.items, errors: load.errors, partial: load.partial);
});

// ─── Filters ──────────────────────────────────────────────────────────────────
/// Optional account filter (null = all accounts).
final inboxConnectionFilterProvider = StateProvider<String?>((ref) => null);

/// Optional reason filter (null = every reason).
final inboxReasonFilterProvider = StateProvider<InboxReason?>((ref) => null);

// ─── Done / snoozed ───────────────────────────────────────────────────────────
class InboxDismissals extends StateNotifier<Map<String, InboxDismissal>> {
  InboxDismissals() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = InboxDismissalStore.read(await SharedPreferences.getInstance());
    } on Object {
      // ignore
    }
  }

  Future<void> _save() async {
    try {
      await InboxDismissalStore.write(
          await SharedPreferences.getInstance(), state);
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

  bool isHidden(InboxItem item, DateTime now) =>
      InboxDismissalStore.isHidden(state, item, now);
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
        partial: r.partial,
        fromCache: r.fromCache,
      ));
});

/// [visibleInboxProvider] narrowed by the account and workspace filters.
/// Used for the reason chips' counts so they match what the list can show.
final scopedInboxProvider = Provider<AsyncValue<InboxResult>>((ref) {
  final conn = ref.watch(inboxConnectionFilterProvider);
  final wsFilter = ref.watch(inboxWorkspaceFilterProvider);
  final workspaces = ref.watch(workspacesProvider);
  bool inWorkspace(InboxItem i) {
    if (wsFilter == null) return true;
    final w = Workspace.resolve(workspaces, i);
    return wsFilter == kUnassignedWorkspace ? w == null : w?.id == wsFilter;
  }

  return ref.watch(visibleInboxProvider).whenData((r) => InboxResult(
        items: r.items
            .where((i) =>
                (conn == null || i.connectionId == conn) && inWorkspace(i))
            .toList(),
        errors: r.errors,
        partial: r.partial,
        fromCache: r.fromCache,
      ));
});

/// [scopedInboxProvider] narrowed by the reason filter.
final filteredInboxProvider = Provider<AsyncValue<InboxResult>>((ref) {
  final reason = ref.watch(inboxReasonFilterProvider);
  return ref.watch(scopedInboxProvider).whenData((r) => InboxResult(
        items: reason == null
            ? r.items
            : r.items.where((i) => i.reasons.contains(reason)).toList(),
        errors: r.errors,
        partial: r.partial,
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
