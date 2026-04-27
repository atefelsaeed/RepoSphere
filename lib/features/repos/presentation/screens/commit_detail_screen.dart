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
          error: e,
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

class _FileTile extends StatefulWidget {
  final CommitFileChange file;
  const _FileTile({required this.file});

  @override
  State<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<_FileTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final file = widget.file;
    final hasDiff = file.patch != null && file.patch!.isNotEmpty;

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
        border: Border.all(
          color: _expanded ? cs.outline : cs.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasDiff ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.circular(8),
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
                  if (hasDiff) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded && hasDiff)
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
    final cs = Theme.of(context).colorScheme;
    final lines = patch.split('\n');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF6F8FA),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: lines.map((line) {
              final (bg, fg) = _lineColors(line, isDark, cs);
              return Container(
                color: bg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                child: Text(
                  line.isEmpty ? ' ' : line,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.6,
                    color: fg,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  (Color, Color) _lineColors(String line, bool isDark, ColorScheme cs) {
    if (line.startsWith('+')) {
      return isDark
          ? (const Color(0xFF1A3A2A), const Color(0xFF3FB950))
          : (const Color(0xFFE6FFEC), const Color(0xFF1A7F37));
    }
    if (line.startsWith('-')) {
      return isDark
          ? (const Color(0xFF3A1A1A), const Color(0xFFFF7B72))
          : (const Color(0xFFFFEEF0), const Color(0xFFCF222E));
    }
    if (line.startsWith('@@')) {
      return isDark
          ? (const Color(0xFF0D2A3A), const Color(0xFF79C0FF))
          : (const Color(0xFFDDF4FF), const Color(0xFF0550AE));
    }
    return (Colors.transparent, cs.onSurfaceVariant);
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
