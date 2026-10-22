import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pull_request_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/issue_comments_provider.dart';
import '../widgets/comment_thread.dart';
import '../widgets/label_chip.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/utils/external_link.dart';
import '../../../../shared/widgets/safe_markdown.dart';

class RepoPrDetailScreen extends ConsumerWidget {
  final RepoEntity repo;
  final PullRequestEntity pr;

  const RepoPrDetailScreen({super.key, required this.repo, required this.pr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final commentsAsync = ref.watch(issueCommentsProvider(
      (owner: repo.ownerLogin, repo: repo.name, number: pr.number),
    ));

    final stateColor = switch (pr.state) {
      PrState.open => const Color(0xFF3FB950),
      PrState.merged => const Color(0xFFA371F7),
      PrState.closed => const Color(0xFFEF4444),
      PrState.draft => const Color(0xFF6B7280),
    };

    final stateLabel = switch (pr.state) {
      PrState.open => l.prOpen,
      PrState.merged => l.prMerged,
      PrState.closed => l.prClosed,
      PrState.draft => l.prDraft,
    };

    final stateIcon = switch (pr.state) {
      PrState.open => Icons.call_merge_rounded,
      PrState.merged => Icons.merge_rounded,
      PrState.closed => Icons.close_rounded,
      PrState.draft => Icons.drafts_outlined,
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.prTitle(pr.number),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(repo.fullName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.openOnProvider('GitHub'),
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => openExternalLink(pr.htmlUrl),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title + state badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pr.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withAlpha(30),
                  border: Border.all(color: stateColor.withAlpha(100)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stateIcon, size: 13, color: stateColor),
                    const SizedBox(width: 5),
                    Text(stateLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: stateColor)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 280.ms),

          const SizedBox(height: 12),

          // Author + meta
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: pr.authorAvatarUrl != null
                    ? NetworkImage(pr.authorAvatarUrl!)
                    : null,
                backgroundColor: cs.surfaceContainerHighest,
                child: pr.authorAvatarUrl == null
                    ? Text(pr.authorLogin[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 8),
              Text(pr.authorLogin,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(l.openedAgo(ago(context, pr.createdAt)),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ).animate(delay: 40.ms).fadeIn(duration: 280.ms),

          const SizedBox(height: 12),

          // Branch info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alt_route_rounded,
                    size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(pr.headBranch,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: cs.onSurfaceVariant),
                ),
                Text(pr.baseBranch,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13)),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 280.ms),

          // Labels
          if (pr.labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pr.labels.map((l) => LabelChip(label: l)).toList(),
            ).animate(delay: 100.ms).fadeIn(duration: 280.ms),
          ],

          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 16),

          // Body
          if (pr.body != null && pr.body!.trim().isNotEmpty)
            SafeMarkdownBody(
              data: pr.body!,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                code: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                codeblockDecoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ).animate(delay: 120.ms).fadeIn(duration: 300.ms)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l.noDescriptionProvided,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ),

          const SizedBox(height: 24),

          // Comments section
          CommentThread(commentsAsync: commentsAsync),
        ],
      ),
    );
  }
}
