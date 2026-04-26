import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/release_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_releases_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class RepoReleasesScreen extends ConsumerWidget {
  final RepoEntity repo;
  const RepoReleasesScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final releasesAsync = ref.watch(
      repoReleasesProvider((owner: repo.ownerLogin, repo: repo.name)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Releases',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(repo.fullName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      body: releasesAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const ShimmerBox(height: 120),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(repoReleasesProvider),
        ),
        data: (releases) {
          if (releases.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.new_releases_outlined,
                      size: 56, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No releases yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ).animate().fadeIn(duration: 300.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(repoReleasesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: releases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _ReleaseTile(
                  release: releases[i],
                  isLatest: i == 0 && !releases[i].isDraft && !releases[i].isPreRelease,
                )
                  .animate(delay: (i * 40).clamp(0, 300).ms)
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOut),
            ),
          );
        },
      ),
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  final ReleaseEntity release;
  final bool isLatest;
  const _ReleaseTile({required this.release, this.isLatest = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.new_releases_outlined,
                    size: 18,
                    color: release.isPreRelease
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3FB950)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    release.displayName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (release.isPreRelease)
                  _Badge('Pre-release', const Color(0xFFF59E0B))
                else if (release.isDraft)
                  _Badge('Draft', cs.onSurfaceVariant)
                else if (isLatest)
                  _Badge('Latest', const Color(0xFF3FB950)),
              ],
            ),
          ),

          // Tag + author + date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outline_rounded,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        release.tagName,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (release.authorAvatarUrl != null) ...[
                  CircleAvatar(
                    radius: 10,
                    backgroundImage:
                        NetworkImage(release.authorAvatarUrl!),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  release.authorLogin,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 6),
                Text(
                  'released ${timeago.format(release.publishedAt)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Body (markdown, collapsed to 3 lines)
          if (release.body != null && release.body!.trim().isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: MarkdownBody(
                data: release.body!,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  code: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          ],

          // Open on GitHub
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(release.htmlUrl),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('View on GitHub'),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
