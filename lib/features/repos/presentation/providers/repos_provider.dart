import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/git/git_provider_type.dart';
import '../../../auth/domain/git_connection.dart';
import '../../../auth/presentation/providers/connections_provider.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../data/git_provider_factory.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/git_provider.dart';

/// First connection of a given type, or null.
GitConnection? _firstConnectionOfType(
    List<GitConnection> conns, GitProviderType type) {
  for (final c in conns) {
    if (c.type == type) return c;
  }
  return null;
}

/// Legacy GitHub datasource — now sourced from the first connected GitHub
/// account so existing per-repo detail providers keep working unchanged.
final githubDatasourceProvider = Provider<GitHubRemoteDatasource?>((ref) {
  final conns = ref.watch(connectionsProvider).valueOrNull ?? const [];
  final gh = _firstConnectionOfType(conns, GitProviderType.github);
  if (gh == null) return null;
  final client = ref.watch(sharedHttpClientProvider);
  return GitHubRemoteDatasource(client: client, token: gh.token);
});

/// The active adapter used for account-level queries (profile, etc.).
/// Prefers GitHub, falls back to the first connected account.
final primaryProviderProvider = Provider<GitProvider?>((ref) {
  final providers = ref.watch(activeProvidersProvider);
  if (providers.isEmpty) return null;
  for (final p in providers) {
    if (p.type == GitProviderType.github) return p;
  }
  return providers.first;
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final provider = ref.watch(primaryProviderProvider);
  if (provider == null) return null;
  return provider.getUser();
});

/// All repositories across every connected account, merged.
final allReposProvider = FutureProvider<List<RepoEntity>>((ref) async {
  final providers = ref.watch(activeProvidersProvider);
  if (providers.isEmpty) return const [];
  final results = await Future.wait(providers.map((p) async {
    try {
      return await p.getRepos();
    } catch (_) {
      return <RepoEntity>[];
    }
  }));
  return results.expand((e) => e).toList();
});

/// Starred repos across providers that support starring.
final starredReposProvider = FutureProvider<List<RepoEntity>>((ref) async {
  final providers = ref
      .watch(activeProvidersProvider)
      .where((p) => p.capabilities.starring)
      .toList();
  if (providers.isEmpty) return const [];
  final results = await Future.wait(providers.map((p) async {
    try {
      return await p.getStarredRepos();
    } catch (_) {
      return <RepoEntity>[];
    }
  }));
  return results.expand((e) => e).toList();
});

enum RepoSort { updated, stars, name, created }

final repoFilterProvider = StateProvider<RepoFilter>((ref) => RepoFilter.all);
final searchQueryProvider = StateProvider<String>((ref) => '');
final repoSortProvider = StateProvider<RepoSort>((ref) => RepoSort.updated);

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
        filtered = filtered
            .where((r) => !r.isFork && r.ownerLogin == userLogin)
            .toList();
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
        filtered
            .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case RepoSort.created:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  });
});
