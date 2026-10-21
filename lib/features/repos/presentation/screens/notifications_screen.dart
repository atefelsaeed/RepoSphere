import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import '../providers/repos_provider.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../l10n/l10n.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsSection,
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifs) => notifs.any((n) => n.unread)
                ? TextButton.icon(
                    onPressed: () async {
                      final ds = ref.read(githubDatasourceProvider);
                      if (ds == null) return;
                      await ds.markAllNotificationsRead();
                      ref.invalidate(notificationsProvider);
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: Text(l.markAllRead),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 10,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: cs.outlineVariant),
          itemBuilder: (_, __) => const ShimmerListTile(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(l.failedLoadNotifications,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(e.toString(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 56, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(l.allCaughtUp,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(l.noNotifications,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ).animate().fadeIn(duration: 300.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: cs.outlineVariant),
              itemBuilder: (ctx, i) => _NotifTile(
                notif: notifs[i],
                onTap: () async {
                  final ds = ref.read(githubDatasourceProvider);
                  if (ds != null && notifs[i].unread) {
                    ds.markNotificationRead(notifs[i].id);
                    ref.invalidate(notificationsProvider);
                  }
                  if (notifs[i].htmlUrl.isNotEmpty) {
                    launchUrl(Uri.parse(notifs[i].htmlUrl),
                        mode: LaunchMode.externalApplication);
                  }
                },
              )
                  .animate(delay: (i * 25).clamp(0, 300).ms)
                  .fadeIn(duration: 250.ms)
                  .slideX(begin: -0.03, curve: Curves.easeOut),
            ),
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationEntity notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 10),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notif.unread ? cs.primary : Colors.transparent,
                ),
              ),
            ),

            // Type icon
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 12),
              child: Icon(
                _typeIcon(notif.subjectType),
                size: 18,
                color: _typeColor(notif.subjectType, cs),
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: notif.unread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.repoFullName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ago(context, notif.updatedAt),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (notif.reason.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _reasonLabel(context.l10n, notif.reason),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded,
                size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'Issue' => Icons.circle_outlined,
        'PullRequest' => Icons.call_merge_rounded,
        'Release' => Icons.new_releases_outlined,
        'Commit' => Icons.commit_rounded,
        'Discussion' => Icons.forum_outlined,
        _ => Icons.notifications_outlined,
      };

  Color _typeColor(String type, ColorScheme cs) => switch (type) {
        'Issue' => const Color(0xFF3FB950),
        'PullRequest' => const Color(0xFFA371F7),
        'Release' => const Color(0xFF54AEFF),
        _ => cs.onSurfaceVariant,
      };

  String _reasonLabel(AppLocalizations l, String reason) => switch (reason) {
        'subscribed' => l.reasonSubscribed,
        'mention' => l.reasonMentioned,
        'assign' => l.reasonAssignedShort,
        'review_requested' => l.reasonReviewRequested,
        'author' => l.reasonAuthor,
        'comment' => l.reasonCommented,
        'team_mention' => l.reasonTeamMention,
        'state_change' => l.reasonStateChange,
        _ => reason,
      };
}
