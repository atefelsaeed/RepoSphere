import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/git_provider_factory.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../providers/inbox_provider.dart';

/// Opens the quick-action sheet (re-run CI, approve, request changes, merge,
/// open in browser) for an inbox [item].
Future<void> showInboxActionSheet(BuildContext context, InboxItem item) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => InboxActionSheet(item: item),
    );

class InboxActionSheet extends ConsumerWidget {
  final InboxItem item;
  const InboxActionSheet({super.key, required this.item});

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
