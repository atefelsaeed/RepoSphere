import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/activity_event_entity.dart';
import '../providers/activity_provider.dart';
import '../providers/repos_provider.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final eventsAsync = ref.watch(activityProvider(user.login));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('@${user.login}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(activityProvider),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 12,
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
              Text('Failed to load activity',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(e.toString(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline_rounded,
                      size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('No recent activity',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ).animate().fadeIn(duration: 300.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activityProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: cs.outlineVariant),
              itemBuilder: (ctx, i) => _EventTile(event: events[i])
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

class _EventTile extends StatelessWidget {
  final ActivityEventEntity event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: event.actorAvatarUrl != null
                ? NetworkImage(event.actorAvatarUrl!)
                : null,
            child: event.actorAvatarUrl == null
                ? Text(
                    event.actorLogin.isNotEmpty
                        ? event.actorLogin[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.labelSmall,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurface),
                    children: [
                      TextSpan(
                        text: event.actorLogin,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${event.summary}'),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        event.repoName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeago.format(event.createdAt),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _eventIcon(event.type),
            size: 16,
            color: _eventColor(event.type, cs),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(String type) => switch (type) {
        'PushEvent' => Icons.commit_rounded,
        'PullRequestEvent' => Icons.call_merge_rounded,
        'IssuesEvent' => Icons.circle_outlined,
        'IssueCommentEvent' ||
        'PullRequestReviewCommentEvent' ||
        'CommitCommentEvent' =>
          Icons.chat_bubble_outline_rounded,
        'ForkEvent' => Icons.fork_right_rounded,
        'WatchEvent' => Icons.star_border_rounded,
        'CreateEvent' => Icons.add_circle_outline_rounded,
        'DeleteEvent' => Icons.remove_circle_outline_rounded,
        'ReleaseEvent' => Icons.new_releases_outlined,
        'PullRequestReviewEvent' => Icons.rate_review_outlined,
        _ => Icons.code_rounded,
      };

  Color _eventColor(String type, ColorScheme cs) => switch (type) {
        'PushEvent' => const Color(0xFF54AEFF),
        'PullRequestEvent' || 'PullRequestReviewEvent' =>
          const Color(0xFF3FB950),
        'IssuesEvent' => const Color(0xFFF59E0B),
        'WatchEvent' => const Color(0xFFF59E0B),
        'ForkEvent' => const Color(0xFFA371F7),
        'ReleaseEvent' => const Color(0xFF3FB950),
        'DeleteEvent' => const Color(0xFFEF4444),
        _ => cs.onSurfaceVariant,
      };
}
