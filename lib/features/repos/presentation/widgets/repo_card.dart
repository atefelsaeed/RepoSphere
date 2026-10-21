import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/language_colors.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/pinned_repos_provider.dart';

/// Short badge code + brand colour per provider (shown on non-GitHub cards).
({String code, Color color}) _providerBadge(GitProviderType t) => switch (t) {
      GitProviderType.gitlab => (code: 'GL', color: const Color(0xFFFC6D26)),
      GitProviderType.azureDevOps =>
        (code: 'AZ', color: const Color(0xFF0078D4)),
      GitProviderType.bitbucket =>
        (code: 'BB', color: const Color(0xFF2684FF)),
      GitProviderType.gitea => (code: 'GT', color: const Color(0xFF609926)),
      GitProviderType.github => (code: 'GH', color: const Color(0xFF6E7681)),
    };

class RepoCard extends ConsumerStatefulWidget {
  final RepoEntity repo;
  final VoidCallback? onTap;

  const RepoCard({super.key, required this.repo, this.onTap});

  @override
  ConsumerState<RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends ConsumerState<RepoCard> {
  bool _hovered = false;
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.repo.htmlUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final repo = widget.repo;
    final isPinned = ref.watch(pinnedReposProvider).contains(repo.id);
    final isGitLab = repo.provider != GitProviderType.github;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? cs.primary.withAlpha(120) : cs.outlineVariant,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: cs.primary.withAlpha(28),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(repo.ownerAvatarUrl),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repo.fullName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Pin indicator
                      if (isPinned) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.push_pin_rounded,
                            size: 12, color: cs.primary),
                      ],
                      // Provider badge (any non-GitHub provider)
                      if (isGitLab) ...[
                        const SizedBox(width: 6),
                        Builder(builder: (_) {
                          final badge = _providerBadge(repo.provider);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: badge.color.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: badge.color.withAlpha(100),
                                  width: 0.5),
                            ),
                            child: Text(
                              badge.code,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: badge.color,
                              ),
                            ),
                          );
                        }),
                      ],
                      // Private badge
                      if (repo.isPrivate) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: cs.outlineVariant, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 10, color: cs.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                'Private',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Repo name
                  Text(
                    repo.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (repo.description != null &&
                      repo.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      repo.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const Spacer(),

                  // Footer: language + stats
                  Row(
                    children: [
                      if (repo.language != null) ...[
                        _LanguageDot(language: repo.language!),
                        const SizedBox(width: 4),
                        Text(
                          repo.language!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (repo.isFork) ...[
                        Icon(Icons.fork_right_rounded,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          'Fork',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.star_border_rounded,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(repo.stargazersCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(repo.updatedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: _copied ? 'Copied!' : 'Copy link',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: _copyLink,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _copied
                                  ? Icons.check_rounded
                                  : Icons.link_rounded,
                              key: ValueKey(_copied),
                              size: 14,
                              color: _copied
                                  ? const Color(0xFF3FB950)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => launchUrl(
                          Uri.parse(repo.htmlUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Icon(Icons.open_in_new_rounded,
                            size: 14, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

class _LanguageDot extends StatelessWidget {
  final String language;
  const _LanguageDot({required this.language});

  @override
  Widget build(BuildContext context) {
    final color =
        kLanguageColors[language] ?? Theme.of(context).colorScheme.secondary;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
