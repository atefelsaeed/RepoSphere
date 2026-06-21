import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/pinned_repos_provider.dart';
import '../providers/repos_provider.dart';
import '../widgets/repo_card.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class ReposScreen extends ConsumerStatefulWidget {
  const ReposScreen({super.key});

  @override
  ConsumerState<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends ConsumerState<ReposScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Cross-provider pagination is handled per-adapter; the unified list loads
    // the first page from each connection. (Infinite scroll: future work.)
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_searchFocus.hasFocus) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.slash:
        _searchFocus.requestFocus();
        return true;
      case LogicalKeyboardKey.keyR:
        _refresh();
        return true;
      case LogicalKeyboardKey.question:
        _showShortcutsDialog();
        return true;
    }
    return false;
  }

  void _showShortcutsDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ShortcutsDialog(),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(allReposProvider);
    ref.invalidate(starredReposProvider);
    ref.invalidate(currentUserProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final filter = ref.watch(repoFilterProvider);
    final query = ref.watch(searchQueryProvider);
    final filteredAsync = ref.watch(filteredReposProvider);
    final pinnedIds = ref.watch(pinnedReposProvider);
    final allRepos = ref.watch(allReposProvider).valueOrNull ?? [];
    final pinnedRepos = (filter == RepoFilter.all && query.isEmpty && pinnedIds.isNotEmpty)
        ? allRepos.where((r) => pinnedIds.contains(r.id)).toList()
        : <RepoEntity>[];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.hub_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'RepoSphere',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Settings
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed('settings'),
          ),
          // Notifications with unread badge
          Builder(builder: (context) {
            final notifs =
                ref.watch(notificationsProvider).valueOrNull ?? [];
            final unread = notifs.where((n) => n.unread).length;
            return IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(fontSize: 10)),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.goNamed('notifications'),
            );
          }),
          // Activity feed
          IconButton(
            tooltip: 'Activity',
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () => context.goNamed('activity'),
          ),
          // Gists
          IconButton(
            tooltip: 'Gists',
            icon: const Icon(Icons.code_rounded),
            onPressed: () => context.goNamed('gists'),
          ),
          // Global search
          IconButton(
            tooltip: 'Explore GitHub',
            icon: const Icon(Icons.travel_explore_rounded),
            onPressed: () => context.goNamed('search'),
          ),
          // Sort dropdown
          PopupMenuButton<RepoSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: ref.watch(repoSortProvider),
            onSelected: (s) =>
                ref.read(repoSortProvider.notifier).state = s,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: RepoSort.updated, child: Text('Last updated')),
              PopupMenuItem(value: RepoSort.stars, child: Text('Stars')),
              PopupMenuItem(value: RepoSort.name, child: Text('Name')),
              PopupMenuItem(value: RepoSort.created, child: Text('Created')),
            ],
          ),
          // Theme toggle
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : ref.watch(themeModeProvider) == ThemeMode.light
                      ? Icons.dark_mode_rounded
                      : Icons.brightness_auto_rounded,
            ),
            onPressed: () async {
              final current = ref.read(themeModeProvider);
              final next = switch (current) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              ref.read(themeModeProvider.notifier).state = next;
              final prefs = await SharedPreferences.getInstance();
              prefs.setString('themeMode', next.name);
            },
          ),
          // Avatar → profile
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => context.goNamed('profile'),
                child: Tooltip(
                  message: 'Profile',
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Disconnect all'),
                  content: const Text(
                      'Remove all connected accounts from this device?'),
                  actions: [
                    TextButton(
                      onPressed: () => ctx.pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => ctx.pop(true),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(connectionsProvider.notifier).removeAll();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: 'Search repositories…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(searchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: RepoFilter.values.map((f) {
                    final isSelected = filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedScale(
                        scale: isSelected ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: FilterChip(
                          label: Text(_filterLabel(f)),
                          selected: isSelected,
                          onSelected: (_) =>
                              ref.read(repoFilterProvider.notifier).state = f,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Pinned repos section
            if (pinnedRepos.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin_rounded,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Pinned',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        scrollDirection: Axis.horizontal,
                        itemCount: pinnedRepos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final r = pinnedRepos[i];
                          return _PinnedChip(
                            repo: r,
                            onTap: () => ctx.goNamed(
                              'repo-detail',
                              pathParameters: {'id': '${r.id}'},
                              extra: r,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: cs.outlineVariant),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

            // Repo count badge
            filteredAsync.when(
              data: (repos) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '${repos.length} repositor${repos.length == 1 ? 'y' : 'ies'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Repo grid / list
            filteredAsync.when(
              data: (repos) {
                if (repos.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No repositories found',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: _RepoGrid(repos: repos),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: _ShimmerGrid(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  error: e,
                  onRetry: _refresh,
                ),
              ),
            ),

            // Footer
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _filterLabel(RepoFilter f) => switch (f) {
        RepoFilter.all => 'All',
        RepoFilter.owned => 'Owned',
        RepoFilter.forked => 'Forked',
        RepoFilter.starred => 'Starred',
        RepoFilter.publicOnly => 'Public',
        RepoFilter.privateOnly => 'Private',
      };
}

class _RepoGrid extends StatelessWidget {
  final List<RepoEntity> repos;
  const _RepoGrid({required this.repos});

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 2
                    : 1;

        if (columns == 1) {
          return SliverList.separated(
            itemCount: repos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => RepoCard(
              repo: repos[i],
              onTap: () => ctx.goNamed(
                'repo-detail',
                pathParameters: {'id': '${repos[i].id}'},
                extra: repos[i],
              ),
            )
                .animate(delay: (i * 40).clamp(0, 400).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, curve: Curves.easeOut),
          );
        }

        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 168,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: repos.length,
          itemBuilder: (ctx, i) => RepoCard(
            repo: repos[i],
            onTap: () => ctx.goNamed(
              'repo-detail',
              pathParameters: {'id': '${repos[i].id}'},
              extra: repos[i],
            ),
          )
              .animate(delay: (i * 40).clamp(0, 400).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
        );
      },
    );
  }
}

class _PinnedChip extends StatelessWidget {
  final RepoEntity repo;
  final VoidCallback onTap;
  const _PinnedChip({required this.repo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
          color: cs.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(repo.ownerAvatarUrl),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    repo.ownerLogin,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              repo.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.star_border_rounded,
                    size: 11, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  '${repo.stargazersCount}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 2
                    : 1;

        if (columns == 1) {
          return SliverList.separated(
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, __) => const ShimmerRepoCard(),
          );
        }

        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 168,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: columns * 3,
          itemBuilder: (_, __) => const ShimmerRepoCard(),
        );
      },
    );
  }
}

class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const shortcuts = [
      ('/','Focus search bar'),
      ('R', 'Refresh repositories'),
      ('?', 'Show this dialog'),
    ];

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard_rounded, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          const Text('Keyboard Shortcuts'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: shortcuts.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    s.$1,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(s.$2, style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
