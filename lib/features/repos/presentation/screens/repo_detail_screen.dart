import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/language_colors.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/is_starred_provider.dart';
import '../providers/pinned_repos_provider.dart';
import '../providers/repo_commits_provider.dart';
import '../providers/repo_contributors_provider.dart';
import '../providers/repo_languages_provider.dart';
import '../providers/repos_provider.dart';
import '../widgets/commit_tile.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/utils/external_link.dart';

class RepoDetailScreen extends ConsumerStatefulWidget {
  final RepoEntity repo;

  const RepoDetailScreen({super.key, required this.repo});

  @override
  ConsumerState<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends ConsumerState<RepoDetailScreen> {
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
    final l = context.l10n;
    final repo = widget.repo;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // GitHub-only sections (commits/languages/contributors/star) are hidden
    // for every non-GitHub provider, since those detail providers are wired to
    // the GitHub API. (Per-provider detail wiring is future work.)
    final isGitLab = repo.provider != GitProviderType.github;
    final isPinned = ref.watch(pinnedReposProvider).contains(repo.id);

    // GitHub-only providers — only watched for GitHub repos
    final commitsAsync = isGitLab
        ? null
        : ref.watch(repoCommitsProvider((owner: repo.ownerLogin, repo: repo.name)));
    final languagesAsync = isGitLab
        ? null
        : ref.watch(repoLanguagesProvider((owner: repo.ownerLogin, repo: repo.name)));
    final contributorsAsync = isGitLab
        ? null
        : ref.watch(repoContributorsProvider((owner: repo.ownerLogin, repo: repo.name)));
    final starArgs = (
      owner: repo.ownerLogin,
      repo: repo.name,
      connectionId: repo.connectionId,
    );
    final isStarredAsync = isGitLab ? null : ref.watch(isStarredProvider(starArgs));

    return Scaffold(
      appBar: AppBar(
        title: Text(repo.name),
        actions: [
          Tooltip(
            message: isPinned ? l.unpin : l.pin,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  key: ValueKey(isPinned),
                  color: isPinned ? cs.primary : null,
                ),
              ),
              onPressed: () => ref
                  .read(pinnedReposProvider.notifier)
                  .toggle(repo.id),
            ),
          ),
          if (!isGitLab) ...[
            FilledButton.icon(
              onPressed: () => context.goNamed(
                'repo-browser',
                pathParameters: {'id': '${repo.id}'},
                extra: (repo: repo, path: '', branch: null),
              ),
              icon: const Icon(Icons.folder_open_rounded, size: 16),
              label: Text(l.browseCode),
            ),
            const SizedBox(width: 8),
            isStarredAsync?.whenOrNull(
              data: (starred) => Tooltip(
                message: starred ? l.unstar : l.star,
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      starred ? Icons.star_rounded : Icons.star_border_rounded,
                      key: ValueKey(starred),
                      color: starred ? const Color(0xFFF59E0B) : null,
                    ),
                  ),
                  onPressed: () async {
                    final ds = ref.read(
                        githubDatasourceForConnectionProvider(
                            repo.connectionId));
                    if (ds == null) return;
                    starred
                        ? await ds.unstarRepo(repo.ownerLogin, repo.name)
                        : await ds.starRepo(repo.ownerLogin, repo.name);
                    ref.invalidate(isStarredProvider(starArgs));
                    ref.invalidate(starredReposProvider);
                  },
                ),
              ),
            ) ?? const SizedBox.shrink(),
            const SizedBox(width: 8),
          ],
          Tooltip(
            message: _copied ? l.copied : l.copyLink,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _copied ? Icons.check_rounded : Icons.link_rounded,
                  key: ValueKey(_copied),
                  color: _copied ? const Color(0xFF3FB950) : null,
                ),
              ),
              onPressed: _copyLink,
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => openExternalLink(repo.htmlUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(l.openOnProvider(repo.provider.label)),
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
                      label: Text(l.filterPrivate,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      side: BorderSide(color: cs.outlineVariant),
                    )
                  else
                    Chip(
                      avatar: Icon(Icons.public_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      label: Text(l.filterPublic,
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

              // Quick nav buttons (GitHub only)
              if (!isGitLab)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NavButton(
                      icon: Icons.call_merge_rounded,
                      label: l.pullRequests,
                      color: const Color(0xFF3FB950),
                      onTap: () => context.goNamed('repo-prs',
                          pathParameters: {'id': '${repo.id}'},
                          extra: repo),
                    ),
                    _NavButton(
                      icon: Icons.circle_outlined,
                      label: l.issues,
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
                      label: l.commits,
                      color: const Color(0xFFA371F7),
                      onTap: () => context.goNamed('repo-commits',
                          pathParameters: {'id': '${repo.id}'},
                          extra: (repo: repo, branch: repo.defaultBranch)),
                    ),
                    _NavButton(
                      icon: Icons.folder_open_rounded,
                      label: l.browseCode,
                      color: cs.secondary,
                      onTap: () => context.goNamed('repo-browser',
                          pathParameters: {'id': '${repo.id}'},
                          extra: (repo: repo, path: '', branch: null)),
                    ),
                    _NavButton(
                      icon: Icons.new_releases_outlined,
                      label: l.releases,
                      color: const Color(0xFF54AEFF),
                      onTap: () => context.goNamed('repo-releases',
                          pathParameters: {'id': '${repo.id}'},
                          extra: repo),
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
                      label: l.forkLabel,
                    ),
                  if (repo.defaultBranch != null)
                    _InfoChip(
                      icon: const Icon(Icons.alt_route_rounded, size: 14),
                      label: repo.defaultBranch!,
                    ),
                ],
              ),

              // GitHub-only: language stats bar, contributors, clone
              if (!isGitLab) ...[
                if (languagesAsync!.hasValue &&
                    languagesAsync.value!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _LanguageBar(languages: languagesAsync.value!),
                ],
                if (contributorsAsync!.hasValue &&
                    contributorsAsync.value!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ContributorsRow(contributors: contributorsAsync.value!),
                ],
                const SizedBox(height: 20),
                _CloneSection(repo: repo),
              ],

              // Topics
              if (repo.topics.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(l.topics, style: theme.textTheme.labelLarge),
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
                      label: l.sortCreated,
                      date: repo.createdAt,
                    ),
                  ),
                  Expanded(
                    child: _DateTile(
                      label: l.sortUpdated,
                      date: repo.updatedAt,
                    ),
                  ),
                ],
              ),

              // GitHub-only: recent commits section
              if (!isGitLab) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.commit_rounded,
                            size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(l.recentCommits,
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
                      label: Text(l.viewAll),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                commitsAsync!.when(
                  data: (commits) => commits.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(l.noCommitsFound,
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
                    child: ErrorView(error: e),
                  ),
                ),
              ],
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
    final l = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
            icon: Icons.star_border_rounded,
            value: repo.stargazersCount,
            label: l.sortStars),
        _StatItem(
            icon: Icons.fork_right_rounded,
            value: repo.forksCount,
            label: l.forks),
        _StatItem(
            icon: Icons.visibility_outlined,
            value: repo.watchersCount,
            label: l.watchers),
        _StatItem(
            icon: Icons.circle_outlined,
            value: repo.openIssuesCount,
            label: l.issues),
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

class _LanguageBar extends StatelessWidget {
  final Map<String, int> languages;
  const _LanguageBar({required this.languages});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = languages.values.fold(0, (a, b) => a + b);
    final sorted = languages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.languages, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: sorted.map((e) {
              final color =
                  kLanguageColors[e.key] ?? cs.primary;
              return Flexible(
                flex: ((e.value / total) * 10000).round(),
                child: Container(height: 8, color: color),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: sorted.take(8).map((e) {
            final pct = (e.value / total * 100).toStringAsFixed(1);
            final color = kLanguageColors[e.key] ?? cs.primary;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('${e.key} $pct%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ContributorsRow extends StatelessWidget {
  final List contributors;
  const _ContributorsRow({required this.contributors});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.contributors, style: theme.textTheme.labelLarge),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: contributors.take(10).map<Widget>((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Tooltip(
                      message:
                          l.contributorTooltip(c.login, c.contributions),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(c.avatarUrl),
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.login,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CloneSection extends StatefulWidget {
  final RepoEntity repo;
  const _CloneSection({required this.repo});

  @override
  State<_CloneSection> createState() => _CloneSectionState();
}

class _CloneSectionState extends State<_CloneSection> {
  bool _httpscopied = false;
  bool _sshCopied = false;
  Timer? _httpsTimer;
  Timer? _sshTimer;

  @override
  void dispose() {
    _httpsTimer?.cancel();
    _sshTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyHttps() async {
    final url =
        'https://github.com/${widget.repo.ownerLogin}/${widget.repo.name}.git';
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _httpscopied = true);
    _httpsTimer?.cancel();
    _httpsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _httpscopied = false);
    });
  }

  Future<void> _copySsh() async {
    final url =
        'git@github.com:${widget.repo.ownerLogin}/${widget.repo.name}.git';
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _sshCopied = true);
    _sshTimer?.cancel();
    _sshTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _sshCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final httpsUrl =
        'https://github.com/${widget.repo.ownerLogin}/${widget.repo.name}.git';
    final sshUrl =
        'git@github.com:${widget.repo.ownerLogin}/${widget.repo.name}.git';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.clone, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _CloneRow(
          label: 'HTTPS',
          url: httpsUrl,
          copied: _httpscopied,
          onCopy: _copyHttps,
        ),
        const SizedBox(height: 6),
        _CloneRow(
          label: 'SSH',
          url: sshUrl,
          copied: _sshCopied,
          onCopy: _copySsh,
        ),
      ],
    );
  }
}

class _CloneRow extends StatelessWidget {
  final String label;
  final String url;
  final bool copied;
  final VoidCallback onCopy;

  const _CloneRow({
    required this.label,
    required this.url,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: copied ? const Color(0xFF3FB950).withAlpha(120) : cs.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: copied ? l.copied : l.copy,
            child: GestureDetector(
              onTap: onCopy,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  key: ValueKey(copied),
                  size: 16,
                  color: copied ? const Color(0xFF3FB950) : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
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
