import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../domain/entities/issue_entity.dart';
import 'repos_provider.dart';

class IssuesState {
  final List<IssueEntity> issues;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String filter; // 'open' | 'closed'

  const IssuesState({
    this.issues = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filter = 'open',
  });

  IssuesState copyWith({
    List<IssueEntity>? issues,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? filter,
  }) =>
      IssuesState(
        issues: issues ?? this.issues,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        filter: filter ?? this.filter,
      );
}

class IssuesNotifier extends StateNotifier<IssuesState> {
  final GitHubRemoteDatasource _ds;
  final String _owner;
  final String _repo;
  int _page = 1;

  IssuesNotifier(this._ds, this._owner, this._repo)
      : super(const IssuesState()) {
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _page = 1;
      state =
          state.copyWith(isLoading: true, issues: [], hasMore: true, error: null);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final models = await _ds.getIssues(_owner, _repo,
          state: state.filter, page: _page, perPage: 30);
      final entities = models.map((m) => m.toEntity()).toList();
      _page++;
      state = state.copyWith(
        issues: reset ? entities : [...state.issues, ...entities],
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

final repoIssuesProvider = StateNotifierProvider.family<IssuesNotifier,
    IssuesState, ({String owner, String repo})>(
  (ref, args) {
    final ds = ref.watch(githubDatasourceProvider);
    return IssuesNotifier(ds!, args.owner, args.repo);
  },
);
