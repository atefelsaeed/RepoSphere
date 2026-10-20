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
