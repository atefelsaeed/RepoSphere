import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../domain/entities/pull_request_entity.dart';
import 'repos_provider.dart';

class PrsState {
  final List<PullRequestEntity> prs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String filter; // 'open' | 'closed' | 'all'

  const PrsState({
    this.prs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filter = 'open',
  });

  PrsState copyWith({
    List<PullRequestEntity>? prs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? filter,
  }) =>
      PrsState(
        prs: prs ?? this.prs,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        filter: filter ?? this.filter,
      );
}

class PrsNotifier extends StateNotifier<PrsState> {
  final GitHubRemoteDatasource _ds;
  final String _owner;
  final String _repo;
  int _page = 1;

  PrsNotifier(this._ds, this._owner, this._repo)
      : super(const PrsState()) {
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _page = 1;
      state = state.copyWith(isLoading: true, prs: [], hasMore: true, error: null);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final models = await _ds.getPullRequests(
        _owner, _repo,
        state: state.filter == 'merged' ? 'closed' : state.filter,
        page: _page,
        perPage: 30,
      );
      var entities = models.map((m) => m.toEntity()).toList();
      if (state.filter == 'merged') {
        entities = entities.where((p) => p.state == PrState.merged).toList();
      }
      _page++;
      state = state.copyWith(
        prs: reset ? entities : [...state.prs, ...entities],
        isLoading: false,
        isLoadingMore: false,
        hasMore: models.length == 30,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> changeFilter(String filter) async {
    state = state.copyWith(filter: filter);
    await _load(reset: true);
  }

  Future<void> loadMore() => _load(reset: false);
  Future<void> refresh() => _load(reset: true);
}

final repoPrsProvider = StateNotifierProvider.family<PrsNotifier, PrsState,
    ({String owner, String repo})>(
  (ref, args) {
    final ds = ref.watch(githubDatasourceProvider);
    return PrsNotifier(ds!, args.owner, args.repo);
  },
);
