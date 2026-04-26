import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/language_colors.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_commits_provider.dart';
import '../widgets/commit_tile.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class RepoDetailScreen extends ConsumerWidget {
  final RepoEntity repo;

  const RepoDetailScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final commitsAsync = ref.watch(
      repoCommitsProvider((owner: repo.ownerLogin, repo: repo.name)),
    );

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
              _StatsRow(repo: repo)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOut),

              const SizedBox(height: 20),

              // Quick nav buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _NavButton(
                    icon: Icons.call_merge_rounded,
                    label: 'Pull Requests',
                    color: const Color(0xFF3FB950),
                    onTap: () => context.goNamed('repo-prs',
                        pathParameters: {'id': '${repo.id}'},
                        extra: repo),
                  ),
                  _NavButton(
                    icon: Icons.circle_outlined,
                    label: 'Issues',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.goNamed('repo-issues',
                        pathParameters: {'id': '${repo.id}'},
                        extra: repo),
                  ),
                  _NavButton(
                    icon: Icons.article_outlined,
                    label: 'README',
                    color: cs.primary,
                    onTap: () => context.goNamed('repo-readme',
                        pathParameters: {'id': '${repo.id}'},
                        extra: repo),
                  ),
                  _NavButton(
                    icon: Icons.commit_rounded,
                    label: 'Commits',
                    color: const Color(0xFFA371F7),
                    onTap: () => context.goNamed('repo-commits',
                        pathParameters: {'id': '${repo.id}'},
                        extra: (repo: repo, branch: repo.defaultBranch)),
                  ),
                  _NavButton(
                    icon: Icons.folder_open_rounded,
                    label: 'Browse Code',
                    color: cs.secondary,
                    onTap: () => context.goNamed('repo-browser',
                        pathParameters: {'id': '${repo.id}'},
                        extra: (repo: repo, path: '')),
                  ),
                ],
              ).animate(delay: 60.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOut),

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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Commits section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.commit_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Recent Commits',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.goNamed(
                      'repo-commits',
                      pathParameters: {'id': '${repo.id}'},
                      extra: (repo: repo, branch: repo.defaultBranch),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('View all'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              commitsAsync.when(
                data: (commits) => commits.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No commits found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant)),
                      )
                    : Column(
                        children: commits.asMap().entries.map((e) {
                          final i = e.key;
                          final c = e.value;
                          return Column(
                            children: [
                              CommitTile(
                                commit: c,
                                onTap: () => context.goNamed(
                                  'commit-detail',
                                  pathParameters: {'id': '${repo.id}'},
                                  extra: (repo: repo, commit: c),
                                ),
                              )
                                  .animate(
                                      delay: (i * 40).clamp(0, 200).ms)
                                  .fadeIn(duration: 250.ms)
                                  .slideX(
                                      begin: -0.04,
                                      curve: Curves.easeOut),
                              if (c != commits.last)
                                Divider(
                                    height: 1, color: cs.outlineVariant),
                            ],
                          );
                        }).toList(),
                      ),
                loading: () => Column(
                  children: List.generate(
                    3,
                    (i) => Column(children: [
                      const ShimmerListTile(),
                      if (i < 2) const Divider(height: 1),
                    ]),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Failed to load commits: $e',
                      style:
                          TextStyle(color: theme.colorScheme.error)),
                ),
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

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered
                  ? widget.color.withAlpha(180)
                  : cs.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(10),
            color: widget.color.withAlpha(_hovered ? 30 : 15),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 14, color: widget.color.withAlpha(160)),
            ],
          ),
        ),
      ),
    );
  }
}
