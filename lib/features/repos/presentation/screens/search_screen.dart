import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/global_search_provider.dart';
import '../providers/recent_searches_provider.dart';
import '../widgets/repo_card.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  void _submit(String q) {
    if (q.trim().isEmpty) return;
    _controller.text = q;
    setState(() => _query = q.trim());
    ref.read(recentSearchesProvider.notifier).add(q.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final recent = ref.watch(recentSearchesProvider);
    final resultsAsync =
        _query.isEmpty ? null : ref.watch(globalSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search all GitHub repositories…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            prefixIcon:
                const Icon(Icons.travel_explore_rounded, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
          onSubmitted: _submit,
        ),
      ),
      body: _buildBody(context, theme, cs, recent, resultsAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    List<String> recent,
    AsyncValue<List<RepoEntity>>? resultsAsync,
  ) {
    if (resultsAsync == null) {
      return _EmptyState(
        recent: recent,
        onSelect: _submit,
        onRemove: (q) =>
            ref.read(recentSearchesProvider.notifier).remove(q),
        onClearAll: () =>
            ref.read(recentSearchesProvider.notifier).clear(),
        theme: theme,
        cs: cs,
      );
    }

    return resultsAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => const ShimmerRepoCard(),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text('Search failed', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(e.toString(),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
      data: (repos) {
        // Save on first data result
        if (repos.isNotEmpty) {
          Future.microtask(() =>
              ref.read(recentSearchesProvider.notifier).add(_query));
        }

        if (repos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No results for "$_query"',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ).animate().fadeIn(duration: 300.ms),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  '${repos.length}+ repositories for "$_query"',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final List<String> recent;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;
  final ThemeData theme;
  final ColorScheme cs;

  const _EmptyState({
    required this.recent,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded,
                size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Search across all of GitHub',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text('Find repos by name, topic, or description',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ).animate().fadeIn(duration: 300.ms),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Recent searches',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        ...recent.asMap().entries.map((e) {
          final i = e.key;
          final q = e.value;
          return ListTile(
            leading: const Icon(Icons.history_rounded, size: 18),
            title: Text(q, style: theme.textTheme.bodyMedium),
            trailing: IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              onPressed: () => onRemove(q),
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => onSelect(q),
          )
              .animate(delay: (i * 30).ms)
              .fadeIn(duration: 200.ms)
              .slideX(begin: -0.03, curve: Curves.easeOut);
        }),
      ],
    );
  }
}
