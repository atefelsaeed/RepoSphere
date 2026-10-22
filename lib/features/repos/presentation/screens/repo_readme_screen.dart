import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_readme_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/utils/external_link.dart';
import '../../../../shared/widgets/remote_markdown_image.dart';

class RepoReadmeScreen extends ConsumerWidget {
  final RepoEntity repo;
  const RepoReadmeScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final readmeAsync = ref.watch(
      repoReadmeProvider((owner: repo.ownerLogin, repo: repo.name)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('README',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(repo.fullName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      body: readmeAsync.when(
        data: (content) {
          if (content == null || content.trim().isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined,
                      size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(l.noReadmeFound,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ).animate().fadeIn(duration: 300.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(repoReadmeProvider),
            child: Markdown(
              imageBuilder: remoteMarkdownImage,
              data: content,
              selectable: true,
              onTapLink: (_, href, __) {
                if (href != null) {
                  openExternalLink(href);
                }
              },
              key: const ValueKey('readme-content'),
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
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: cs.primary, width: 3),
                  ),
                  color: cs.primaryContainer.withAlpha(60),
                ),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: cs.outlineVariant),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
            ).animate().fadeIn(duration: 350.ms),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ShimmerBox(height: 28, width: 220),
            const SizedBox(height: 20),
            ...List.generate(3, (_) => const Column(children: [
              ShimmerBox(height: 13),
              SizedBox(height: 6),
              ShimmerBox(height: 13),
              SizedBox(height: 6),
              ShimmerBox(height: 13, width: 280),
              SizedBox(height: 16),
            ])),
            ShimmerBox(height: 22, width: 160),
            const SizedBox(height: 12),
            ...List.generate(4, (_) => const Column(children: [
              ShimmerBox(height: 13),
              SizedBox(height: 6),
              ShimmerBox(height: 13, width: 320),
              SizedBox(height: 6),
              ShimmerBox(height: 13),
              SizedBox(height: 16),
            ])),
            ShimmerBox(height: 80, radius: 8),
            const SizedBox(height: 16),
            ...List.generate(2, (_) => const Column(children: [
              ShimmerBox(height: 13),
              SizedBox(height: 6),
              ShimmerBox(height: 13, width: 260),
              SizedBox(height: 16),
            ])),
          ],
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(repoReadmeProvider),
        ),
      ),
    );
  }
}
