import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../providers/repos_provider.dart';
import '../widgets/repo_card.dart';
import '../../../../shared/widgets/error_view.dart';

class ReposScreen extends ConsumerStatefulWidget {
  const ReposScreen({super.key});

  @override
  ConsumerState<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends ConsumerState<ReposScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final filteredAsync = ref.watch(filteredReposProvider);

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
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Disconnect'),
                  content:
                      const Text('Remove your GitHub token from this device?'),
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
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_filterLabel(f)),
                        selected: filter == f,
                        onSelected: (_) =>
                            ref.read(repoFilterProvider.notifier).state = f,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: _RepoGrid(repos: repos),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: _refresh,
                ),
              ),
            ),
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
            ),
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
          ),
        );
      },
    );
  }
}
