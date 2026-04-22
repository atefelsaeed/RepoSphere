import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/language_colors.dart';
import '../../domain/entities/repo_entity.dart';

class RepoDetailScreen extends StatelessWidget {
  final RepoEntity repo;

  const RepoDetailScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(repo.name),
        actions: [
          FilledButton.icon(
            onPressed: () => context.goNamed(
              'repo-browser',
              pathParameters: {'id': '${repo.id}'},
              extra: (repo: repo, path: ''),
            ),
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: const Text('Browse Code'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.link_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: repo.htmlUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  width: 260,
                ),
              );
            },
          ),
          FilledButton.tonalIcon(
            onPressed: () => launchUrl(
              Uri.parse(repo.htmlUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open on GitHub'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Owner + repo name
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(repo.ownerAvatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.ownerLogin,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          repo.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (repo.isPrivate)
                    Chip(
                      avatar: Icon(Icons.lock_outline_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      label: Text('Private',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      side: BorderSide(color: cs.outlineVariant),
                    )
                  else
                    Chip(
                      avatar: Icon(Icons.public_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      label: Text('Public',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                ],
              ),

              // Description
              if (repo.description != null &&
                  repo.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  repo.description!,
                  style: theme.textTheme.bodyLarge,
                ),
              ],

              const SizedBox(height: 24),

              // Stats row
              _StatsRow(repo: repo),

              const SizedBox(height: 24),

              // Language & fork badge
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (repo.language != null)
                    _InfoChip(
                      icon: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: kLanguageColors[repo.language!] ??
                              cs.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: repo.language!,
                    ),
                  if (repo.isFork)
                    _InfoChip(
                      icon: const Icon(Icons.fork_right_rounded, size: 14),
                      label: 'Fork',
                    ),
                  if (repo.defaultBranch != null)
                    _InfoChip(
                      icon: const Icon(Icons.alt_route_rounded, size: 14),
                      label: repo.defaultBranch!,
                    ),
                ],
              ),

              // Topics
              if (repo.topics.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Topics', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: repo.topics
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          backgroundColor: cs.primaryContainer,
                          labelStyle:
                              TextStyle(color: cs.onPrimaryContainer),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Created',
                      date: repo.createdAt,
                    ),
                  ),
                  Expanded(
                    child: _DateTile(
                      label: 'Last updated',
                      date: repo.updatedAt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final RepoEntity repo;
  const _StatsRow({required this.repo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
            icon: Icons.star_border_rounded,
            value: repo.stargazersCount,
            label: 'Stars'),
        _StatItem(
            icon: Icons.fork_right_rounded,
            value: repo.forksCount,
            label: 'Forks'),
        _StatItem(
            icon: Icons.visibility_outlined,
            value: repo.watchersCount,
            label: 'Watchers'),
        _StatItem(
            icon: Icons.circle_outlined,
            value: repo.openIssuesCount,
            label: 'Issues'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  const _StatItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          _format(value),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _InfoChip extends StatelessWidget {
  final Widget icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  const _DateTile({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          timeago.format(date),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
