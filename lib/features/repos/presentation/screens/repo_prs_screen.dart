import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/pull_request_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_prs_provider.dart';
import '../widgets/label_chip.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../l10n/l10n.dart';

class RepoPrsScreen extends ConsumerStatefulWidget {
  final RepoEntity repo;
  const RepoPrsScreen({super.key, required this.repo});

  @override
  ConsumerState<RepoPrsScreen> createState() => _RepoPrsScreenState();
}

class _RepoPrsScreenState extends ConsumerState<RepoPrsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();
  final _filters = ['open', 'closed', 'merged'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ({String owner, String repo}) get _args =>
      (owner: widget.repo.ownerLogin, repo: widget.repo.name);

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(repoPrsProvider(_args).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(repoPrsProvider(_args));
    final notifier = ref.read(repoPrsProvider(_args).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.pullRequests,
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.repo.fullName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) => notifier.changeFilter(_filters[i]),
          tabs: [
            Tab(text: l.tabOpen),
            Tab(text: l.tabClosed),
            Tab(text: l.tabMerged),
          ],
        ),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 10,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (_, __) => const ShimmerListTile(),
          );
        }
        if (state.error != null && state.prs.isEmpty) {
          return ErrorView.message(state.error!, onRetry: notifier.refresh);
        }
        if (state.prs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.merge_type_rounded,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(switch (state.filter) { 'open' => l.noOpenPrs, 'closed' => l.noClosedPrs, _ => l.noMergedPrs },
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
            padding: const EdgeInsets.all(16),
            itemCount: state.prs.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (ctx, i) {
              if (i == state.prs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: state.isLoadingMore
                      ? const ShimmerListTile()
                      : Center(
                          child: TextButton(
                            onPressed: notifier.loadMore,
                            child: Text(l.loadMore),
                          ),
                        ),
                );
              }
              return _PrTile(repo: widget.repo, pr: state.prs[i])
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

class _PrTile extends StatelessWidget {
  final RepoEntity repo;
  final PullRequestEntity pr;
  const _PrTile({required this.repo, required this.pr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: () => context.goNamed(
        'pr-detail',
        pathParameters: {'id': '${repo.id}'},
        extra: (repo: repo, pr: pr),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State icon
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(
                _stateIcon(pr.state),
                color: _stateColor(pr.state),
                size: 20,
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    pr.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),

                  // Meta: #number · branch info · time
                  Wrap(
                    spacing: 6,
                    children: [
                      Text(
                        '#${pr.number}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text('·',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alt_route_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${pr.headBranch} → ${pr.baseBranch}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      Text('·',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      Text(
                        ago(context, pr.updatedAt),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Labels + comments
                  Row(
                    children: [
                      ...pr.labels.take(3).map((l) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: LabelChip(label: l),
                          )),
                      const Spacer(),
                      if (pr.commentsCount > 0) ...[
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text('${pr.commentsCount}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: pr.authorAvatarUrl != null
                            ? NetworkImage(pr.authorAvatarUrl!)
                            : null,
                        child: pr.authorAvatarUrl == null
                            ? Text(pr.authorLogin[0].toUpperCase(),
                                style: const TextStyle(fontSize: 9))
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _stateIcon(PrState state) => switch (state) {
        PrState.open => Icons.call_merge_rounded,
        PrState.merged => Icons.merge_rounded,
        PrState.closed => Icons.close_rounded,
        PrState.draft => Icons.drafts_outlined,
      };

  Color _stateColor(PrState state) => switch (state) {
        PrState.open => const Color(0xFF3FB950),
        PrState.merged => const Color(0xFFA371F7),
        PrState.closed => const Color(0xFFEF4444),
        PrState.draft => const Color(0xFF6B7280),
      };
}
