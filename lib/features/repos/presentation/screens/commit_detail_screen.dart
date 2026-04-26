import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/commit_entity.dart';
import '../../domain/entities/commit_detail_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/commit_detail_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class CommitDetailScreen extends ConsumerWidget {
  final RepoEntity repo;
  final CommitEntity commit;

  const CommitDetailScreen({
    super.key,
    required this.repo,
    required this.commit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final detailAsync = ref.watch(commitDetailProvider(
      (owner: repo.ownerLogin, repo: repo.name, sha: commit.sha),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(commit.shortSha,
                style: const TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            Text(repo.fullName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open on GitHub',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => launchUrl(Uri.parse(commit.htmlUrl),
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => _CommitDetailBody(detail: detail),
        loading: () => _CommitDetailShimmer(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(commitDetailProvider),
        ),
      ),
    );
  }
}

class _CommitDetailBody extends StatelessWidget {
  final CommitDetailEntity detail;
  const _CommitDetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Commit message header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.firstLine,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (detail.bodyText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(detail.bodyText,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: detail.authorAvatarUrl != null
                        ? NetworkImage(detail.authorAvatarUrl!)
                        : null,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: detail.authorAvatarUrl == null
                        ? Text(detail.authorName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 10))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detail.authorLogin ?? detail.authorName,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'committed ${timeago.format(detail.date)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04),

        const SizedBox(height: 16),

        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${detail.files.length} file${detail.files.length == 1 ? '' : 's'} changed',
                  style: theme.textTheme.labelMedium),
              const SizedBox(width: 16),
              Text('+${detail.totalAdditions}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: const Color(0xFF3FB950),
                          fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('-${detail.totalDeletions}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600)),
            ],
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 12),

        // File list
        ...detail.files.asMap().entries.map((e) {
          final i = e.key;
          final file = e.value;
          return _FileTile(file: file)
              .animate(delay: (80 + i * 30).clamp(80, 500).ms)
              .fadeIn(duration: 220.ms)
              .slideY(begin: 0.04, curve: Curves.easeOut);
        }),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  final CommitFileChange file;
  const _FileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusColor = switch (file.status) {
      'added' => const Color(0xFF3FB950),
      'removed' => const Color(0xFFEF4444),
      'renamed' => const Color(0xFFF59E0B),
      _ => const Color(0xFF54AEFF),
    };

    final statusLabel = switch (file.status) {
      'added' => 'A',
      'removed' => 'D',
      'renamed' => 'R',
      _ => 'M',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file.filename,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            if (file.additions > 0)
              Text('+${file.additions}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF3FB950),
                      fontWeight: FontWeight.w600)),
            if (file.additions > 0 && file.deletions > 0)
              const SizedBox(width: 6),
            if (file.deletions > 0)
              Text('-${file.deletions}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CommitDetailShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(height: 100, radius: 10),
        const SizedBox(height: 16),
        ShimmerBox(height: 44, radius: 8),
        const SizedBox(height: 12),
        ...List.generate(
          8,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ShimmerBox(height: 44, radius: 8),
          ),
        ),
      ],
    );
  }
}
