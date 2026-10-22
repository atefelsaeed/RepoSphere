import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/issue_comments_provider.dart';
import '../widgets/comment_thread.dart';
import '../widgets/label_chip.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/utils/external_link.dart';
import '../../../../shared/widgets/safe_markdown.dart';

class RepoIssueDetailScreen extends ConsumerWidget {
  final RepoEntity repo;
  final IssueEntity issue;

  const RepoIssueDetailScreen(
      {super.key, required this.repo, required this.issue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final commentsAsync = ref.watch(issueCommentsProvider(
      (owner: repo.ownerLogin, repo: repo.name, number: issue.number),
    ));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOpen = issue.state == IssueState.open;

    final stateColor =
        isOpen ? const Color(0xFF3FB950) : const Color(0xFFA371F7);
    final stateIcon = isOpen
        ? Icons.circle_outlined
        : Icons.check_circle_outline_rounded;
    final stateLabel = isOpen ? l.prOpen : l.prClosed;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.issueTitle(issue.number),
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
            onPressed: () => openExternalLink(issue.htmlUrl),
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
                  issue.title,
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

          // Author + time
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: issue.authorAvatarUrl != null
                    ? NetworkImage(issue.authorAvatarUrl!)
                    : null,
                backgroundColor: cs.surfaceContainerHighest,
                child: issue.authorAvatarUrl == null
                    ? Text(issue.authorLogin[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 8),
              Text(issue.authorLogin,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(
                isOpen
                    ? l.openedAgo(ago(context, issue.createdAt))
                    : l.closedAgo(ago(context, issue.closedAt ?? issue.updatedAt)),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ).animate(delay: 40.ms).fadeIn(duration: 280.ms),

          // Labels
          if (issue.labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  issue.labels.map((l) => LabelChip(label: l)).toList(),
            ).animate(delay: 80.ms).fadeIn(duration: 280.ms),
          ],

          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 16),

          // Body
          if (issue.body != null && issue.body!.trim().isNotEmpty)
            SafeMarkdownBody(
              data: issue.body!,
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
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms)
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

          CommentThread(commentsAsync: commentsAsync),
        ],
      ),
    );
  }
}
