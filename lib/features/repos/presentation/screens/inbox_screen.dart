import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../../data/git_provider_factory.dart';
import '../providers/inbox_provider.dart';
import '../providers/workspaces_provider.dart';
import '../../../../shared/widgets/error_view.dart';

/// Home screen: a prioritised "what needs me today" list across every
/// connected account and provider.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final inbox = ref.watch(filteredInboxProvider);
    final visible = ref.watch(visibleInboxProvider).valueOrNull;
    final scoped = ref.watch(scopedInboxProvider).valueOrNull;
    final connections = ref.watch(connectionsProvider).valueOrNull ?? const [];
    final filter = ref.watch(inboxConnectionFilterProvider);
    final reasonFilter = ref.watch(inboxReasonFilterProvider);
    final workspaces = ref.watch(workspacesProvider);
    final wsFilter = ref.watch(inboxWorkspaceFilterProvider);

    Future<void> refresh() async {
      final done = Completer<void>();
      final sub = ref.listenManual(inboxProvider, (_, next) {
        final v = next.valueOrNull;
        if ((v != null && !v.fromCache || next.hasError) && !done.isCompleted) {
          done.complete();
        }
      });
      ref.invalidate(inboxProvider);
      // The first emission may be the cached snapshot; wait for the live one.
      await done.future.timeout(const Duration(seconds: 45), onTimeout: () {});
      sub.close();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.hub_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Workspaces',
            icon: const Icon(Icons.business_center_outlined),
            onPressed: () => context.pushNamed('workspaces'),
          ),
          IconButton(
            tooltip: 'Repositories',
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => context.goNamed('repos'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (workspaces.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _wsChip(ref, 'All', null, wsFilter, null),
                  for (final w in workspaces)
                    _wsChip(ref, w.name, w.id, wsFilter, Color(w.color)),
                  if (visible != null &&
                      visible.items.any((i) =>
                          Workspace.resolve(workspaces, i) == null))
                    _wsChip(ref, 'Unassigned', kUnassignedWorkspace, wsFilter,
                        null),
                ],
              ),
            )
          else if (connections.length > 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(ref, 'All', null, filter),
                  for (final c in connections)
                    _chip(ref, c.displayName, c.id, filter),
                ],
              ),
            ),
          if (scoped != null && scoped.items.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _reasonChip(ref, 'Everything', null, reasonFilter,
                      scoped.items.length),
                  for (final r in InboxReason.values)
                    if (scoped.items.any((i) => i.reasons.contains(r)))
                      _reasonChip(
                          ref,
                          r.label,
                          r,
                          reasonFilter,
                          scoped.items
                              .where((i) => i.reasons.contains(r))
                              .length),
                ],
              ),
            ),
          if (inbox.valueOrNull case final r?
              when r.errors.isNotEmpty || r.fromCache)
            _StatusBanner(result: r, onRetry: refresh),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: inbox.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(inboxProvider),
                  ),
                ]),
                data: (r) => r.items.isEmpty
                    ? (r.errors.isNotEmpty
                        ? ListView()
                        : const _EmptyInbox())
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: r.items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (_, i) => _DismissibleTile(
                            key: ValueKey(r.items[i].key), item: r.items[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wsChip(WidgetRef ref, String label, String? id, String? selected,
          Color? dot) =>
      Padding(
        padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
        child: ChoiceChip(
          avatar: dot == null ? null : CircleAvatar(backgroundColor: dot, radius: 6),
          showCheckmark: false,
          label: Text(label),
          selected: selected == id,
          onSelected: (_) =>
              ref.read(inboxWorkspaceFilterProvider.notifier).state = id,
        ),
      );

  Widget _reasonChip(WidgetRef ref, String label, InboxReason? reason,
          InboxReason? selected, int count) =>
      Padding(
        padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        child: FilterChip(
          label: Text('$label · $count'),
          selected: selected == reason,
          visualDensity: VisualDensity.compact,
          onSelected: (_) =>
              ref.read(inboxReasonFilterProvider.notifier).state = reason,
        ),
      );

  Widget _chip(WidgetRef ref, String label, String? id, String? selected) =>
      Padding(
        padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected == id,
          onSelected: (_) =>
              ref.read(inboxConnectionFilterProvider.notifier).state = id,
        ),
      );
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.check_circle_outline_rounded, size: 64, color: cs.primary),
        const SizedBox(height: 16),
        Center(
          child: Text('You\'re all caught up',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Nothing needs your attention right now.',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}

class _InboxTile extends ConsumerWidget {
  final InboxItem item;
  const _InboxTile({required this.item});

  Color _color(ColorScheme cs, InboxReason r) => switch (r) {
        InboxReason.ciFailed ||
        InboxReason.conflicts ||
        InboxReason.changesRequested =>
          cs.error,
        InboxReason.reviewRequested => cs.primary,
        InboxReason.assigned => cs.tertiary,
        InboxReason.mentioned => cs.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isPr = item.kind == InboxItemKind.pullRequest;
    final ws = ref.watch(workspaceForItemProvider(item));
    final sep = isPr && item.provider == GitProviderType.gitlab ? '!' : '#';
    return ListTile(
      leading: Icon(
        isPr ? Icons.call_merge_rounded : Icons.error_outline_rounded,
        color: _color(cs, item.primaryReason),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.repoFullName}$sep${item.number}'
              ' · ${item.provider.label} · ${item.accountLogin}'
              ' · ${timeago.format(item.updatedAt)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (ws != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(ws.color)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(ws.name,
                        style: TextStyle(fontSize: 11, color: Color(ws.color))),
                  ),
                for (final r in item.reasons)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _color(cs, r).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(r.label,
                        style:
                            TextStyle(fontSize: 11, color: _color(cs, r))),
                  ),
              ],
            ),
          ],
        ),
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _ActionSheet(item: item),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final InboxResult result;
  final Future<void> Function() onRetry;
  const _StatusBanner({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasErrors = result.errors.isNotEmpty;
    final fg = hasErrors ? cs.onErrorContainer : cs.onSurfaceVariant;
    return Container(
      width: double.infinity,
      color: hasErrors ? cs.errorContainer : cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(hasErrors ? Icons.cloud_off_rounded : Icons.history_rounded,
              size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasErrors
                  ? "Couldn't load: ${result.errors.keys.join(', ')}. "
                      'Results from other accounts may be incomplete.'
                  : 'Showing saved results — refreshing…',
              style: TextStyle(fontSize: 12, color: fg),
            ),
          ),
          if (hasErrors)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Swipe right = done, swipe left = snooze.
class _DismissibleTile extends ConsumerWidget {
  final InboxItem item;
  const _DismissibleTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(inboxDismissalsProvider.notifier);
    Widget bg(IconData icon, String text, Alignment a, Color c) => Container(
          color: c,
          alignment: a,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: cs.onPrimary),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: cs.onPrimary)),
            ],
          ),
        );
    return Dismissible(
      key: ValueKey('d-${item.key}'),
      background:
          bg(Icons.check_rounded, 'Done', Alignment.centerLeft, cs.primary),
      secondaryBackground:
          bg(Icons.snooze_rounded, 'Snooze', Alignment.centerRight, cs.tertiary),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) return true;
        final d = await showModalBottomSheet<Duration>(
          context: context,
          showDragHandle: true,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, dur) in const [
                  ('Later today (4 hours)', Duration(hours: 4)),
                  ('Tomorrow', Duration(days: 1)),
                  ('Next week', Duration(days: 7)),
                ])
                  ListTile(
                    leading: const Icon(Icons.snooze_rounded),
                    title: Text(label),
                    onTap: () => Navigator.pop(context, dur),
                  ),
              ],
            ),
          ),
        );
        if (d != null) notifier.snooze(item, d);
        return false; // the list rebuilds without the item via state
      },
      onDismissed: (_) {
        notifier.markDone(item);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: const Text('Marked done'),
            action: SnackBarAction(
                label: 'Undo', onPressed: () => notifier.restore(item)),
          ));
      },
      child: _InboxTile(item: item),
    );
  }
}

class _ActionSheet extends ConsumerWidget {
  final InboxItem item;
  const _ActionSheet({required this.item});

  Future<void> _run(BuildContext context, WidgetRef ref, PrAction action,
      {String? comment}) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await runInboxAction(ref, item, action, comment: comment);
      messenger.showSnackBar(SnackBar(
          content: Text(switch (action) {
        PrAction.approve => 'Approved',
        PrAction.requestChanges => 'Changes requested',
        PrAction.merge => 'Merged',
        PrAction.rerunCi => 'CI re-run started',
      })));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm')),
          ],
        ),
      ) ??
      false;

  Future<String?> _askComment(BuildContext context) async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request changes'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'What needs to change?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Send')),
        ],
      ),
    );
    c.dispose();
    return (r == null || r.isEmpty) ? null : r;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final caps = ref
            .read(providerForConnectionProvider(item.connectionId))
            ?.capabilities ??
        const ProviderCapabilities();
    final isPr = item.kind == InboxItemKind.pullRequest;
    final failedCi = item.reasons.contains(InboxReason.ciFailed);
    final ref0 = '${item.repoFullName} #${item.number}';

    Widget action(IconData icon, String label, VoidCallback onTap,
            {Color? color}) =>
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(label),
          onTap: onTap,
        );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      '${item.repoFullName} · ${item.provider.label} · ${item.accountLogin}',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const Divider(height: 1),
            if (isPr && failedCi && caps.rerunCi)
              action(Icons.replay_rounded, 'Re-run failed CI',
                  () => _run(context, ref, PrAction.rerunCi)),
            if (isPr && caps.approvePullRequests)
              action(Icons.check_circle_outline_rounded, 'Approve', () async {
                if (await _confirm(context, 'Approve?',
                    'Approve $ref0 as ${item.accountLogin}?')) {
                  if (context.mounted) {
                    await _run(context, ref, PrAction.approve);
                  }
                }
              }),
            if (isPr && caps.requestChanges)
              action(Icons.rate_review_outlined, 'Request changes', () async {
                final c = await _askComment(context);
                if (c != null && context.mounted) {
                  await _run(context, ref, PrAction.requestChanges, comment: c);
                }
              }),
            if (isPr && caps.mergePullRequests)
              action(Icons.merge_rounded, 'Merge', () async {
                if (await _confirm(context, 'Merge?',
                    "Merge $ref0? This can't be undone from here.")) {
                  if (context.mounted) {
                    await _run(context, ref, PrAction.merge);
                  }
                }
              }, color: cs.error),
            action(Icons.open_in_new_rounded, 'Open in browser', () {
              Navigator.pop(context);
              final uri = Uri.tryParse(item.htmlUrl);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
