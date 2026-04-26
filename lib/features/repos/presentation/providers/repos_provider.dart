import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../auth/data/secure_token_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../data/datasources/gitlab_remote_datasource.dart';
import '../../data/repositories/github_repo_repository_impl.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/git_provider.dart';

final _httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final githubDatasourceProvider = Provider<GitHubRemoteDatasource?>((ref) {
  final token = ref.watch(authProvider).valueOrNull;
  if (token == null || token.isEmpty) return null;
  final client = ref.watch(_httpClientProvider);
  return GitHubRemoteDatasource(client: client, token: token);
});

final gitProviderProvider = Provider<GitProvider?>((ref) {
  final datasource = ref.watch(githubDatasourceProvider);
  if (datasource == null) return null;
  return GitHubRepoRepositoryImpl(datasource);
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final provider = ref.watch(gitProviderProvider);
  if (provider == null) return null;
  return provider.getUser();
});

final allReposProvider = FutureProvider<List<RepoEntity>>((ref) async {
  final provider = ref.watch(gitProviderProvider);
  final githubRepos = provider == null ? <RepoEntity>[] : await provider.getRepos();
  final gitlabRepos = await ref.watch(gitlabReposProvider.future);
  return [...githubRepos, ...gitlabRepos];
});

final starredReposProvider = FutureProvider<List<RepoEntity>>((ref) async {
  final provider = ref.watch(gitProviderProvider);
  if (provider == null) return [];
  return provider.getStarredRepos();
});

enum RepoSort { updated, stars, name, created }

final repoFilterProvider = StateProvider<RepoFilter>((ref) => RepoFilter.all);
final searchQueryProvider = StateProvider<String>((ref) => '');
final repoSortProvider = StateProvider<RepoSort>((ref) => RepoSort.updated);

/// GitLab datasource — null when no token is saved.
final gitlabDatasourceProvider =
    FutureProvider<GitLabRemoteDatasource?>((ref) async {
  // Re-evaluate when GitHub auth changes (logout clears all tokens too)
  ref.watch(authProvider);
  final token = await SecureTokenStorage.readGitLabToken();
  if (token == null || token.isEmpty) return null;
  return GitLabRemoteDatasource(client: http.Client(), token: token);
});

/// Returns the connected GitLab username, or null if not connected.
final gitlabConnectedUserProvider = FutureProvider<String?>((ref) async {
  final dsAsync = ref.watch(gitlabDatasourceProvider);
  final ds = dsAsync.valueOrNull;
  if (ds == null) return null;
  try {
    return await ds.verifyToken();
  } catch (_) {
    return null;
  }
});

final gitlabReposProvider = FutureProvider<List<RepoEntity>>((ref) async {
  final dsAsync = ref.watch(gitlabDatasourceProvider);
  final ds = dsAsync.valueOrNull;
  if (ds == null) return [];
  final projects = await ds.getProjects();
  return projects.map((p) => p.toEntity()).toList();
});

final filteredReposProvider = Provider<AsyncValue<List<RepoEntity>>>((ref) {
  final filter = ref.watch(repoFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final sort = ref.watch(repoSortProvider);
  final userLogin = ref.watch(currentUserProvider).valueOrNull?.login ?? '';

  final baseAsync = filter == RepoFilter.starred
      ? ref.watch(starredReposProvider)
      : ref.watch(allReposProvider);

  return baseAsync.whenData((repos) {
    var filtered = repos;

    switch (filter) {
      case RepoFilter.owned:
        filtered =
            filtered.where((r) => !r.isFork && r.ownerLogin == userLogin).toList();
      case RepoFilter.forked:
        filtered = filtered.where((r) => r.isFork).toList();
      case RepoFilter.publicOnly:
        filtered = filtered.where((r) => !r.isPrivate).toList();
      case RepoFilter.privateOnly:
        filtered = filtered.where((r) => r.isPrivate).toList();
      default:
        break;
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.name.toLowerCase().contains(query) ||
              (r.description?.toLowerCase().contains(query) ?? false) ||
              (r.language?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    switch (sort) {
      case RepoSort.updated:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case RepoSort.stars:
        filtered.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
      case RepoSort.name:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case RepoSort.created:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  });
});
