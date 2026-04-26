import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/repo_entity.dart';
import '../providers/global_search_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
        ),
      ),
      body: _buildBody(context, theme, cs, resultsAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    AsyncValue<List<RepoEntity>>? resultsAsync,
  ) {
    // Empty state — no query yet
    if (resultsAsync == null) {
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
            Icon(Icons.error_outline_rounded,
                size: 48, color: cs.error),
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
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
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
