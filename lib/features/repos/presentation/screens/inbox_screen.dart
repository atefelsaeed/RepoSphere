import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../providers/inbox_provider.dart';
import '../../../../shared/widgets/error_view.dart';

/// Home screen: a prioritised "what needs me today" list across every
/// connected account and provider.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final inbox = ref.watch(filteredInboxProvider);
    final connections = ref.watch(connectionsProvider).valueOrNull ?? const [];
    final filter = ref.watch(inboxConnectionFilterProvider);

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
          if (connections.length > 1)
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(inboxProvider);
                await ref.read(inboxProvider.future);
              },
              child: inbox.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(inboxProvider),
                  ),
                ]),
                data: (items) => items.isEmpty
                    ? const _EmptyInbox()
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (_, i) => _InboxTile(item: items[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

class _InboxTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPr = item.kind == InboxItemKind.pullRequest;
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
      onTap: () {
        final uri = Uri.tryParse(item.htmlUrl);
        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}
