import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/commits_notifier.dart';
import '../providers/repo_branches_provider.dart';
import '../widgets/commit_tile.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class RepoCommitsScreen extends ConsumerStatefulWidget {
  final RepoEntity repo;
  final String? initialBranch;

  const RepoCommitsScreen({
    super.key,
    required this.repo,
    this.initialBranch,
  });

  @override
  ConsumerState<RepoCommitsScreen> createState() => _RepoCommitsScreenState();
}

class _RepoCommitsScreenState extends ConsumerState<RepoCommitsScreen> {
  final _scrollController = ScrollController();
  late String _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch =
        widget.initialBranch ?? widget.repo.defaultBranch ?? 'main';
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(commitsNotifierProvider(_notifierArgs).notifier).loadMore();
    }
  }

  ({String owner, String repo, String initialBranch}) get _notifierArgs => (
        owner: widget.repo.ownerLogin,
        repo: widget.repo.name,
        initialBranch: _selectedBranch,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final branchesAsync = ref.watch(repoBranchesProvider(
      (owner: widget.repo.ownerLogin, repo: widget.repo.name),
    ));

    final commitsState = ref.watch(commitsNotifierProvider(_notifierArgs));
    final notifier = ref.read(commitsNotifierProvider(_notifierArgs).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Commits',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              widget.repo.fullName,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: branchesAsync.when(
              data: (branches) => _BranchSelector(
                branches: branches.map((b) => b.name).toList(),
                selected: _selectedBranch,
                defaultBranch: widget.repo.defaultBranch ?? 'main',
                onChanged: (branch) {
                  setState(() => _selectedBranch = branch);
                  ref
                      .read(commitsNotifierProvider(_notifierArgs).notifier)
                      .changeBranch(branch);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => _BranchSelector(
                branches: [_selectedBranch],
                selected: _selectedBranch,
                defaultBranch: _selectedBranch,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
      body: Builder(builder: (context) {
        if (commitsState.isLoading) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 10,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (_, __) => const ShimmerListTile(),
          );
        }

        if (commitsState.error != null && commitsState.commits.isEmpty) {
          return ErrorView(
            message: commitsState.error!,
            onRetry: notifier.refresh,
          );
        }

        if (commitsState.commits.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.commit_rounded,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No commits on this branch',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ).animate().fadeIn(duration: 300.ms),
          );
        }

        return RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount:
                commitsState.commits.length + (commitsState.hasMore ? 1 : 0),
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (ctx, i) {
              if (i == commitsState.commits.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: commitsState.isLoadingMore
                      ? const ShimmerListTile()
                      : Center(
                          child: TextButton(
                            onPressed: notifier.loadMore,
                            child: const Text('Load more'),
                          ),
                        ),
                );
              }
              return CommitTile(
                commit: commitsState.commits[i],
                onTap: () => context.goNamed(
                  'commit-detail',
                  pathParameters: {'id': '${widget.repo.id}'},
                  extra: (repo: widget.repo, commit: commitsState.commits[i]),
                ),
              )
                  .animate(delay: (i * 30).clamp(0, 300).ms)
                  .fadeIn(duration: 250.ms)
                  .slideX(begin: -0.04, curve: Curves.easeOut);
            },
          ),
        );
      }),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  final List<String> branches;
  final String selected;
  final String defaultBranch;
  final ValueChanged<String> onChanged;

  const _BranchSelector({
    required this.branches,
    required this.selected,
    required this.defaultBranch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allBranches =
        branches.contains(selected) ? branches : [selected, ...branches];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.unfold_more_rounded, size: 18),
          items: allBranches.map((b) {
            return DropdownMenuItem(
              value: b,
              child: Row(
                children: [
                  Icon(Icons.alt_route_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: b == defaultBranch
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (b == defaultBranch) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'default',
                        style: TextStyle(
                            fontSize: 10, color: cs.onPrimaryContainer),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
