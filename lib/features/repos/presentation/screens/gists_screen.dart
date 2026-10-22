import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gist_entity.dart';
import '../providers/gists_provider.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/utils/external_link.dart';

class GistsScreen extends ConsumerWidget {
  const GistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final gistsAsync = ref.watch(gistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.yourGists,
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(gistsProvider),
          ),
        ],
      ),
      body: gistsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const ShimmerBox(height: 90),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(l.failedLoadGists,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(e.toString(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (gists) {
          if (gists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code_off_rounded,
                      size: 56, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(l.noGistsYet,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ).animate().fadeIn(duration: 300.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(gistsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: gists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _GistCard(gist: gists[i])
                  .animate(delay: (i * 35).clamp(0, 300).ms)
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.05, curve: Curves.easeOut),
            ),
          );
        },
      ),
    );
  }
}

class _GistCard extends StatelessWidget {
  final GistEntity gist;
  const _GistCard({required this.gist});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openExternalLink(gist.htmlUrl),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: cs.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + public badge
            Row(
              children: [
                const Icon(Icons.code_rounded, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gist.displayTitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: gist.isPublic
                        ? const Color(0xFF3FB950).withAlpha(25)
                        : cs.surfaceContainerHighest,
                    border: Border.all(
                      color: gist.isPublic
                          ? const Color(0xFF3FB950).withAlpha(100)
                          : cs.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gist.isPublic ? l.filterPublic : l.gistSecret,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: gist.isPublic
                          ? const Color(0xFF3FB950)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            // Files
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: gist.files.take(5).map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file_outlined,
                          size: 11, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        f.name,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (f.language != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          f.language!,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),

            // Footer
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.update_rounded,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  l.updatedAgo(ago(context, gist.updatedAt)),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (gist.commentsCount > 0) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    '${gist.commentsCount}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const Spacer(),
                Icon(Icons.open_in_new_rounded,
                    size: 13, color: cs.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
