import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/item_detail_entity.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/utils/external_link.dart';
import '../../../../shared/widgets/remote_markdown_image.dart';
import '../providers/item_detail_provider.dart';
import '../widgets/inbox_action_sheet.dart';

/// In-app view of an inbox PR/MR or issue: description, changed files with
/// diffs, and discussion, with the quick actions one tap away.
class ItemDetailScreen extends ConsumerWidget {
  final InboxItem item;
  const ItemDetailScreen({super.key, required this.item});

  String get _ref {
    final sep = item.kind == InboxItemKind.pullRequest &&
            item.provider == GitProviderType.gitlab
        ? '!'
        : '#';
    return '${item.repoFullName}$sep${item.number}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final detail = ref.watch(itemDetailProvider(item));
    final isPr = item.kind == InboxItemKind.pullRequest;

    return Scaffold(
      appBar: AppBar(
        title: Text(_ref, style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: l.actionOpenInBrowser,
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => launchUrl(Uri.parse(item.htmlUrl),
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => showInboxActionSheet(context, item),
            icon: Icon(isPr ? Icons.bolt_rounded : Icons.more_horiz_rounded),
            label: Text(isPr ? l.detailActions : l.detailMore),
          ),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(itemDetailProvider(item)),
        ),
        data: (d) => _Body(item: item, detail: d),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final InboxItem item;
  final ItemDetail detail;
  const _Body({required this.item, required this.detail});

  Color _stateColor(String s) => switch (s) {
        'merged' => const Color(0xFFA371F7),
        'closed' => const Color(0xFFEF4444),
        'draft' => const Color(0xFF6B7280),
        _ => const Color(0xFF3FB950),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = context.l10n;
    final sc = _stateColor(detail.state);
    final stateLabel = switch (detail.state) {
      'merged' => l.stateMerged,
      'closed' => l.stateClosed,
      'draft' => l.stateDraft,
      _ => l.stateOpen,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(detail.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Pill(label: stateLabel, color: sc),
            for (final r in item.reasons)
              _Pill(label: r.localized(l), color: cs.primary, soft: true),
            Text(
              '${detail.authorLogin} · ${ago(context, detail.createdAt)}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        if (detail.headBranch != null && detail.baseBranch != null) ...[
          const SizedBox(height: 10),
          // Branch names are code: keep them left-to-right in RTL languages.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text('${detail.headBranch}  →  ${detail.baseBranch}',
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (detail.body.trim().isNotEmpty)
          MarkdownBody(
imageBuilder: remoteMarkdownImage,
            data: detail.body,
            selectable: true,
            onTapLink: (_, href, __) {
              if (href != null) {
                openExternalLink(href);
              }
            },
          )
        else
          Text(l.detailNoDescription,
              style: TextStyle(color: cs.onSurfaceVariant)),
        if (detail.files.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(l.detailFilesChanged(detail.files.length),
              trailing: '+${detail.additions}  −${detail.deletions}'),
          const SizedBox(height: 8),
          for (final f in detail.files) _FileDiff(file: f),
        ],
        const SizedBox(height: 24),
        _SectionTitle(l.detailDiscussion(detail.comments.length)),
        const SizedBox(height: 8),
        if (detail.comments.isEmpty)
          Text(l.detailNoComments, style: TextStyle(color: cs.onSurfaceVariant))
        else
          for (final c in detail.comments) _Comment(comment: c),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  const _SectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (trailing != null)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(trailing!,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: cs.onSurfaceVariant)),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool soft;
  const _Pill({required this.label, required this.color, this.soft = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: soft ? 0.12 : 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

class _Comment extends StatelessWidget {
  final DetailComment comment;
  const _Comment({required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${comment.authorLogin} · ${ago(context, comment.createdAt)}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          MarkdownBody(data: comment.body, selectable: true),
        ],
      ),
    );
  }
}

/// Collapsible changed file with a coloured unified diff.
class _FileDiff extends StatelessWidget {
  final DiffFile file;
  const _FileDiff({required this.file});

  static const _maxLines = 400;

  IconData get _icon => switch (file.status) {
        'added' => Icons.add_box_outlined,
        'removed' => Icons.indeterminate_check_box_outlined,
        'renamed' => Icons.drive_file_rename_outline_rounded,
        _ => Icons.edit_note_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        dense: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(_icon, size: 18),
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(file.path,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
        // Some providers (Azure DevOps) list changed files without line counts.
        subtitle: file.patch == null && file.additions == 0 && file.deletions == 0
            ? null
            : Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('+${file.additions}  −${file.deletions}',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ),
              ),
        childrenPadding: EdgeInsets.zero,
        children: [
          if (file.patch == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(context.l10n.detailNoDiff,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            )
          else
            _DiffView(patch: file.patch!),
        ],
      ),
    );
  }
}

class _DiffView extends StatelessWidget {
  final String patch;
  const _DiffView({required this.patch});

  @override
  Widget build(BuildContext context) {
    final lines = patch.split('\n');
    final shown = lines.length > _FileDiff._maxLines
        ? lines.sublist(0, _FileDiff._maxLines)
        : lines;
    final dark = Theme.of(context).brightness == Brightness.dark;

    Color? bg(DiffLineKind k) => switch (k) {
          DiffLineKind.added =>
            const Color(0xFF3FB950).withValues(alpha: dark ? 0.18 : 0.15),
          DiffLineKind.removed =>
            const Color(0xFFEF4444).withValues(alpha: dark ? 0.18 : 0.12),
          DiffLineKind.hunk =>
            const Color(0xFF3B82F6).withValues(alpha: dark ? 0.15 : 0.10),
          DiffLineKind.context => null,
        };

    // Code stays left-to-right in RTL languages. Lines are at least as wide as
    // the card so the colour bands span it.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in shown)
                    Container(
                      color: bg(classifyDiffLine(line)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 1),
                      child: Text(
                        line.isEmpty ? ' ' : line,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  if (lines.length > shown.length)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                          context.l10n
                              .detailMoreLines(lines.length - shown.length),
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
