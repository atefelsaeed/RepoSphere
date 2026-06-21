import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/git/git_provider_type.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/repo_issues_provider.dart';
import '../widgets/create_issue_sheet.dart';
import '../widgets/label_chip.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class RepoIssuesScreen extends ConsumerStatefulWidget {
  final RepoEntity repo;
  const RepoIssuesScreen({super.key, required this.repo});

  @override
  ConsumerState<RepoIssuesScreen> createState() => _RepoIssuesScreenState();
}

class _RepoIssuesScreenState extends ConsumerState<RepoIssuesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      ref.read(repoIssuesProvider(_args).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(repoIssuesProvider(_args));
    final notifier = ref.read(repoIssuesProvider(_args).notifier);

    return Scaffold(
      floatingActionButton: widget.repo.provider == GitProviderType.github
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CreateIssueSheet(
                  repo: widget.repo,
                  onCreated: notifier.refresh,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Issue'),
            )
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Issues',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.repo.fullName,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) =>
              notifier.changeFilter(i == 0 ? 'open' : 'closed'),
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Closed'),
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
        if (state.error != null && state.issues.isEmpty) {
          return ErrorView.message(state.error!, onRetry: notifier.refresh);
        }
        if (state.issues.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle_outlined,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No ${state.filter} issues',
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
            itemCount: state.issues.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (ctx, i) {
              if (i == state.issues.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: state.isLoadingMore
                      ? const ShimmerListTile()
                      : Center(
                          child: TextButton(
                            onPressed: notifier.loadMore,
                            child: const Text('Load more'),
                          ),
                        ),
                );
              }
              return _IssueTile(repo: widget.repo, issue: state.issues[i])
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

class _IssueTile extends StatelessWidget {
  final RepoEntity repo;
  final IssueEntity issue;
  const _IssueTile({required this.repo, required this.issue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOpen = issue.state == IssueState.open;

    return InkWell(
      onTap: () => context.goNamed(
        'issue-detail',
        pathParameters: {'id': '${repo.id}'},
        extra: (repo: repo, issue: issue),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(
                isOpen
                    ? Icons.circle_outlined
                    : Icons.check_circle_outline_rounded,
                color: isOpen
                    ? const Color(0xFF3FB950)
                    : const Color(0xFFA371F7),
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      Text('#${issue.number}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      Text('·',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      Text(
                        isOpen
                            ? 'opened ${timeago.format(issue.createdAt)}'
                            : 'closed ${timeago.format(issue.closedAt ?? issue.updatedAt)}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text('·',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      Text('by ${issue.authorLogin}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                  if (issue.labels.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: issue.labels
                          .take(4)
                          .map((l) => LabelChip(label: l))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (issue.commentsCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text('${issue.commentsCount}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
