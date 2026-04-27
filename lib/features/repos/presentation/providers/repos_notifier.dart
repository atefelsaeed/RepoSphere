import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../domain/entities/repo_entity.dart';
import 'repos_provider.dart';

class ReposState {
  final List<RepoEntity> repos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const ReposState({
    this.repos = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  ReposState copyWith({
    List<RepoEntity>? repos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      ReposState(
        repos: repos ?? this.repos,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class ReposNotifier extends StateNotifier<ReposState> {
  final GitHubRemoteDatasource? _ds;
  int _page = 1;
  static const _perPage = 30;

  ReposNotifier(this._ds) : super(const ReposState()) {
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    final ds = _ds;
    if (ds == null) {
      state = const ReposState(repos: [], isLoading: false, hasMore: false);
      return;
    }
    if (reset) {
      _page = 1;
      state = state.copyWith(isLoading: true, repos: [], hasMore: true, clearError: true);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final models = await ds.getRepos(page: _page, perPage: _perPage);
      final entities = models.map((m) => m.toEntity()).toList();
      _page++;
      state = state.copyWith(
        repos: reset ? entities : [...state.repos, ...entities],
        isLoading: false,
        isLoadingMore: false,
        hasMore: models.length == _perPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e,
        hasMore: false,
      );
    }
  }

  Future<void> loadMore() => _load(reset: false);
  Future<void> refresh() => _load(reset: true);
}

final reposNotifierProvider =
    StateNotifierProvider<ReposNotifier, ReposState>((ref) {
  final ds = ref.watch(githubDatasourceProvider);
  return ReposNotifier(ds);
});
