import '../repos/domain/entities/inbox_item_entity.dart';

/// Reasons worth interrupting the user for. Assignments and mentions stay in
/// the Inbox but never raise a notification.
const urgentReasons = {
  InboxReason.ciFailed,
  InboxReason.changesRequested,
  InboxReason.conflicts,
  InboxReason.reviewRequested,
};

/// Identity of one (item, urgent reason) pair. A new reason on an item we
/// already alerted about counts as new.
String alertSignature(InboxItem item, InboxReason reason) =>
    '${item.key}#${reason.name}';

Iterable<String> _signatures(InboxItem item) => item.reasons
    .where(urgentReasons.contains)
    .map((r) => alertSignature(item, r));

class AlertPlan {
  /// Items to tell the user about now.
  final List<InboxItem> fresh;

  /// Signatures to remember. Only what is *currently* urgent, so something
  /// that was fixed and breaks again alerts again.
  final Set<String> nextSeen;
  const AlertPlan(this.fresh, this.nextSeen);
}

/// Decides what to notify. [seen] null means first run: remember everything
/// without alerting, so enabling notifications doesn't dump the backlog.
AlertPlan planAlerts(List<InboxItem> items, Set<String>? seen) {
  final next = {for (final i in items) ..._signatures(i)};
  if (seen == null) return AlertPlan(const [], next);
  final fresh =
      items.where((i) => _signatures(i).any((s) => !seen.contains(s))).toList();
  return AlertPlan(fresh, next);
}

/// Notification text for [fresh] (non-empty, most urgent first).
({String title, String body}) alertText(List<InboxItem> fresh) {
  String line(InboxItem i) =>
      '${i.primaryReason.label} · ${i.repoFullName}#${i.number}';
  final title = fresh.length == 1
      ? fresh.first.title
      : '${fresh.length} items need your attention';
  final lines = fresh.take(3).map(line).toList();
  if (fresh.length > 3) lines.add('and ${fresh.length - 3} more');
  return (
    title: title,
    body: fresh.length == 1 ? line(fresh.first) : lines.join('\n'),
  );
}
