import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../domain/entities/commit_entity.dart';
import 'repos_provider.dart';

class CommitsState {
  final List<CommitEntity> commits;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String branch;

  const CommitsState({
    this.commits = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.branch = '',
  });

  CommitsState copyWith({
    List<CommitEntity>? commits,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? branch,
  }) =>
      CommitsState(
        commits: commits ?? this.commits,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        branch: branch ?? this.branch,
      );
}

class CommitsNotifier extends StateNotifier<CommitsState> {
  final GitHubRemoteDatasource _ds;
  final String _owner;
  final String _repo;
  int _page = 1;

  CommitsNotifier(this._ds, this._owner, this._repo, String initialBranch)
      : super(CommitsState(branch: initialBranch)) {
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _page = 1;
      state = state.copyWith(isLoading: true, commits: [], hasMore: true, error: null);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final models = await _ds.getCommits(
        _owner,
        _repo,
        branch: state.branch,
        page: _page,
        perPage: 30,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      _page++;
      state = state.copyWith(
        commits: reset ? entities : [...state.commits, ...entities],
        isLoading: false,
        isLoadingMore: false,
        hasMore: models.length == 30,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> changeBranch(String branch) async {
    state = state.copyWith(branch: branch);
    await _load(reset: true);
  }

  Future<void> loadMore() => _load(reset: false);

  Future<void> refresh() => _load(reset: true);
}

final commitsNotifierProvider = StateNotifierProvider.family<CommitsNotifier,
    CommitsState, ({String owner, String repo, String initialBranch})>(
  (ref, args) {
    final ds = ref.watch(githubDatasourceProvider);
    return CommitsNotifier(ds!, args.owner, args.repo, args.initialBranch);
  },
);
