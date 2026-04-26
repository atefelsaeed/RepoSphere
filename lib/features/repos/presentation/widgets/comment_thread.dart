import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/issue_comment_entity.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class CommentThread extends StatelessWidget {
  final AsyncValue<List<IssueCommentEntity>> commentsAsync;
  const CommentThread({super.key, required this.commentsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return commentsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text('Comments', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          ...List.generate(
            2,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 80),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (comments) {
        if (comments.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${comments.length} comment${comments.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...comments.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              return CommentCard(comment: c)
                  .animate(delay: (i * 40).clamp(0, 200).ms)
                  .fadeIn(duration: 260.ms);
            }),
          ],
        );
      },
    );
  }
}

class CommentCard extends StatelessWidget {
  final IssueCommentEntity comment;
  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                  bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundImage: comment.authorAvatarUrl != null
                      ? NetworkImage(comment.authorAvatarUrl!)
                      : null,
                  backgroundColor: cs.surface,
                  child: comment.authorAvatarUrl == null
                      ? Text(
                          comment.authorLogin.isNotEmpty
                              ? comment.authorLogin[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 9),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(comment.authorLogin,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(
                  'commented ${timeago.format(comment.createdAt)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(comment.htmlUrl),
                      mode: LaunchMode.externalApplication),
                  child: Icon(Icons.open_in_new_rounded,
                      size: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: comment.body.trim().isNotEmpty
                ? MarkdownBody(
                    data: comment.body,
                    selectable: true,
                    onTapLink: (_, href, __) {
                      if (href != null) {
                        launchUrl(Uri.parse(href),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(theme).copyWith(
                      code: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  )
                : Text('(empty comment)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
