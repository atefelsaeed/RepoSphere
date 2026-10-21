import '../../../../core/git/git_provider_type.dart';

/// Why an item landed in the inbox. Declaration order is priority order
/// (most urgent first) — see [InboxReason.priority].
enum InboxReason {
  ciFailed,
  changesRequested,
  conflicts,
  reviewRequested,
  assigned,
  mentioned;

  int get priority => index;

  String get label => switch (this) {
        InboxReason.ciFailed => 'CI failed',
        InboxReason.changesRequested => 'Changes requested',
        InboxReason.conflicts => 'Merge conflicts',
        InboxReason.reviewRequested => 'Review requested',
        InboxReason.assigned => 'Assigned to you',
        InboxReason.mentioned => 'Mentioned',
      };
}

enum InboxItemKind { pullRequest, issue }

/// One-tap actions on an inbox PR/MR, gated by [ProviderCapabilities].
enum PrAction { approve, requestChanges, merge, rerunCi }

/// Items from one account plus the errors of queries that failed while others
/// succeeded (so the UI can say "some results may be missing").
class InboxBatch {
  final List<InboxItem> items;
  final List<Object> failures;
  const InboxBatch(this.items, [this.failures = const []]);

  bool get isPartial => failures.isNotEmpty;
}

/// Runs all [queries] for one account. Individual failures are tolerated and
/// reported in [InboxBatch.failures] as long as at least one query succeeds;
/// if *all* fail, the first error is rethrown so the UI can tell the user
/// instead of showing a false "all clear".
Future<InboxBatch> collectInbox(
    Iterable<Future<List<InboxItem>> Function()> queries) async {
  final outcomes = await Future.wait(queries.map((q) async {
    try {
      return (items: await q(), error: null as Object?);
    } on Exception catch (e) {
      return (items: const <InboxItem>[], error: e as Object?);
    }
  }));
  final failures = outcomes.where((o) => o.error != null).toList();
  if (failures.isNotEmpty && failures.length == outcomes.length) {
    throw failures.first.error!;
  }
  return InboxBatch(
    InboxItem.mergeAndSort(outcomes.expand((o) => o.items)),
    failures.map((f) => f.error!).toList(),
  );
}

/// A single "needs your attention" entry, normalised across providers.
class InboxItem {
  final String connectionId;
  final GitProviderType provider;
  final String accountLogin;
  final InboxItemKind kind;
  final String repoFullName;
  final int number;
  final String title;
  final String htmlUrl;
  final DateTime updatedAt;
  final String? authorLogin;

  /// All reasons this item matched, most urgent first.
  final List<InboxReason> reasons;

  const InboxItem({
    required this.connectionId,
    required this.provider,
    required this.accountLogin,
    required this.kind,
    required this.repoFullName,
    required this.number,
    required this.title,
    required this.htmlUrl,
    required this.updatedAt,
    required this.reasons,
    this.authorLogin,
  });

  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        'provider': provider.slug,
        'accountLogin': accountLogin,
        'kind': kind.name,
        'repoFullName': repoFullName,
        'number': number,
        'title': title,
        'htmlUrl': htmlUrl,
        'updatedAt': updatedAt.toIso8601String(),
        'authorLogin': authorLogin,
        'reasons': reasons.map((r) => r.name).toList(),
      };

  static InboxItem fromJson(Map<String, dynamic> j) => InboxItem(
        connectionId: j['connectionId'] as String,
        provider: GitProviderType.fromSlug(j['provider'] as String),
        accountLogin: j['accountLogin'] as String,
        kind: InboxItemKind.values.byName(j['kind'] as String),
        repoFullName: j['repoFullName'] as String,
        number: j['number'] as int,
        title: j['title'] as String,
        htmlUrl: j['htmlUrl'] as String,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        authorLogin: j['authorLogin'] as String?,
        reasons: (j['reasons'] as List)
            .map((r) => InboxReason.values.byName(r as String))
            .toList(),
      );

  InboxReason get primaryReason => reasons.first;

  /// Identity used to merge the same PR/issue found by several queries.
  String get key => '$connectionId|${kind.name}|$repoFullName|$number';

  InboxItem withReasons(List<InboxReason> r) => InboxItem(
        connectionId: connectionId,
        provider: provider,
        accountLogin: accountLogin,
        kind: kind,
        repoFullName: repoFullName,
        number: number,
        title: title,
        htmlUrl: htmlUrl,
        updatedAt: updatedAt,
        authorLogin: authorLogin,
        reasons: r,
      );

  /// Merges duplicates (same [key]) into one item carrying every reason, then
  /// sorts by urgency of the primary reason, newest first within a tier.
  static List<InboxItem> mergeAndSort(Iterable<InboxItem> items) {
    final byKey = <String, InboxItem>{};
    for (final item in items) {
      final existing = byKey[item.key];
      if (existing == null) {
        byKey[item.key] = item.withReasons(_sorted(item.reasons));
      } else {
        byKey[item.key] =
            existing.withReasons(_sorted({...existing.reasons, ...item.reasons}));
      }
    }
    final out = byKey.values.toList()
      ..sort((a, b) {
        final p = a.primaryReason.priority.compareTo(b.primaryReason.priority);
        return p != 0 ? p : b.updatedAt.compareTo(a.updatedAt);
      });
    return out;
  }

  static List<InboxReason> _sorted(Iterable<InboxReason> r) =>
      r.toSet().toList()..sort((a, b) => a.priority.compareTo(b.priority));
}
