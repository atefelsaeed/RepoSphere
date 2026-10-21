import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../data/git_provider_factory.dart';
import '../../data/inbox_loader.dart';
import '../../../../l10n/l10n.dart';
import '../providers/inbox_provider.dart';
import '../widgets/inbox_action_sheet.dart';
import '../providers/workspaces_provider.dart';
import '../../../../shared/widgets/error_view.dart';

/// Home screen: a prioritised "what needs me today" list across every
/// connected account and provider.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
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
            Text(l.inboxTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.tooltipWorkspaces,
            icon: const Icon(Icons.business_center_outlined),
            onPressed: () => context.pushNamed('workspaces'),
          ),
          IconButton(
            tooltip: l.tooltipRepositories,
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => context.goNamed('repos'),
          ),
          IconButton(
            tooltip: l.tooltipSettings,
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
                  _wsChip(ref, l.filterAll, null, wsFilter, null),
                  for (final w in workspaces)
                    _wsChip(ref, w.name, w.id, wsFilter, Color(w.color)),
                  if (visible != null &&
                      visible.items
                          .any((i) => Workspace.resolve(workspaces, i) == null))
                    _wsChip(ref, l.filterUnassigned, kUnassignedWorkspace,
                        wsFilter, null),
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
                  _chip(ref, l.filterAll, null, filter),
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
                  _reasonChip(
                      ref,
                      l.filterWithCount(
                          l.filterEverything, scoped.items.length),
                      null,
                      reasonFilter),
                  for (final r in InboxReason.values)
                    if (scoped.items.any((i) => i.reasons.contains(r)))
                      _reasonChip(
                          ref,
                          l.filterWithCount(
                              r.localized(l),
                              scoped.items
                                  .where((i) => i.reasons.contains(r))
                                  .length),
                          r,
                          reasonFilter),
                ],
              ),
            ),
          if (inbox.valueOrNull case final r?
              when r.errors.isNotEmpty || r.partial.isNotEmpty || r.fromCache)
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
                    ? (r.errors.isNotEmpty ? ListView() : const _EmptyInbox())
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
        padding: const EdgeInsetsDirectional.only(end: 8, top: 6, bottom: 6),
        child: ChoiceChip(
          avatar: dot == null
              ? null
              : CircleAvatar(backgroundColor: dot, radius: 6),
          showCheckmark: false,
          label: Text(label),
          selected: selected == id,
          onSelected: (_) =>
              ref.read(inboxWorkspaceFilterProvider.notifier).state = id,
        ),
      );

  Widget _reasonChip(WidgetRef ref, String label, InboxReason? reason,
          InboxReason? selected) =>
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 8, top: 4, bottom: 4),
        child: FilterChip(
          label: Text(label),
          selected: selected == reason,
          visualDensity: VisualDensity.compact,
          onSelected: (_) =>
              ref.read(inboxReasonFilterProvider.notifier).state = reason,
        ),
      );

  Widget _chip(WidgetRef ref, String label, String? id, String? selected) =>
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 8, top: 6, bottom: 6),
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
    final l = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.check_circle_outline_rounded, size: 64, color: cs.primary),
        const SizedBox(height: 16),
        Center(
          child: Text(l.emptyTitle,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Center(
          child:
              Text(l.emptyBody, style: TextStyle(color: cs.onSurfaceVariant)),
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
    final l = context.l10n;
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
              ' · ${ago(context, item.updatedAt)}',
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
                    child: Text(r.localized(l),
                        style: TextStyle(fontSize: 11, color: _color(cs, r))),
                  ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        final caps = ref
            .read(providerForConnectionProvider(item.connectionId))
            ?.capabilities;
        if (caps?.itemDetail ?? false) {
          context.pushNamed('inbox-item', extra: item);
        } else {
          showInboxActionSheet(context, item);
        }
      },
      onLongPress: () => showInboxActionSheet(context, item),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final InboxResult result;
  final Future<void> Function() onRetry;
  const _StatusBanner({required this.result, required this.onRetry});

  /// One line per problem, e.g. "GitHub · atef: GitHub is rate limiting…".
  List<String> _lines(AppLocalizations l) => [
        for (final e in result.errors.entries)
          l.bannerCouldntLoad(
              e.key, inboxErrorText(e.value, fallback: l.errNetwork)),
        for (final e in result.partial.entries)
          l.bannerPartial(
              e.key, inboxErrorText(e.value, fallback: l.errNetwork)),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    final lines = _lines(l);
    final problem = lines.isNotEmpty;
    final fg = problem ? cs.onErrorContainer : cs.onSurfaceVariant;
    return Container(
      width: double.infinity,
      color: problem ? cs.errorContainer : cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(problem ? Icons.cloud_off_rounded : Icons.history_rounded,
              size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              problem ? lines.join('\n') : l.bannerSavedRefreshing,
              style: TextStyle(fontSize: 12, color: fg),
            ),
          ),
          if (problem) TextButton(onPressed: onRetry, child: Text(l.retry)),
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
    final l = context.l10n;
    final notifier = ref.read(inboxDismissalsProvider.notifier);
    Widget bg(IconData icon, String text, AlignmentGeometry a, Color c) =>
        Container(
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
      background: bg(Icons.check_rounded, l.swipeDone,
          AlignmentDirectional.centerStart, cs.primary),
      secondaryBackground: bg(Icons.snooze_rounded, l.swipeSnooze,
          AlignmentDirectional.centerEnd, cs.tertiary),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) return true;
        final d = await showModalBottomSheet<Duration>(
          context: context,
          showDragHandle: true,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, dur) in [
                  (l.snoozeLater, const Duration(hours: 4)),
                  (l.snoozeTomorrow, const Duration(days: 1)),
                  (l.snoozeNextWeek, const Duration(days: 7)),
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
            content: Text(l.markedDone),
            action: SnackBarAction(
                label: l.undo, onPressed: () => notifier.restore(item)),
          ));
      },
      child: _InboxTile(item: item),
    );
  }
}
