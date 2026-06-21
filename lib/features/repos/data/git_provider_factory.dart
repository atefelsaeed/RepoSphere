import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/git/git_provider_type.dart';
import '../../auth/domain/git_connection.dart';
import '../../auth/presentation/providers/connections_provider.dart';
import '../domain/entities/repo_entity.dart';
import '../domain/repositories/git_provider.dart';
import 'datasources/azure_remote_datasource.dart';
import 'datasources/github_remote_datasource.dart';
import 'datasources/gitlab_remote_datasource.dart';
import 'repositories/azure_repo_repository_impl.dart';
import 'repositories/github_repo_repository_impl.dart';
import 'repositories/gitlab_repo_repository_impl.dart';

/// Shared HTTP client for all provider adapters (closed on dispose).
final sharedHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Builds the concrete [GitProvider] adapter for a connection.
/// Returns null for provider types not yet implemented.
GitProvider? buildGitProvider(GitConnection connection, http.Client client) {
  switch (connection.type) {
    case GitProviderType.github:
      return GitHubRepoRepositoryImpl(
        GitHubRemoteDatasource(client: client, token: connection.token),
        connection,
      );
    case GitProviderType.gitlab:
      return GitLabRepoRepositoryImpl(
        GitLabRemoteDatasource(
          client: client,
          token: connection.token,
          baseUrl: connection.baseUrl,
        ),
        connection,
      );
    case GitProviderType.azureDevOps:
      final org = connection.baseUrl;
      if (org == null || org.isEmpty) return null;
      return AzureRepoRepositoryImpl(
        AzureRemoteDatasource(
          client: client,
          pat: connection.token,
          orgUrl: org,
        ),
        connection,
      );
    case GitProviderType.bitbucket:
    case GitProviderType.gitea:
      // Implemented in later phases.
      return null;
  }
}

/// All connected accounts as ready-to-use adapters.
final activeProvidersProvider = Provider<List<GitProvider>>((ref) {
  final connections = ref.watch(connectionsProvider).valueOrNull ?? const [];
  final client = ref.watch(sharedHttpClientProvider);
  return connections
      .map((c) => buildGitProvider(c, client))
      .whereType<GitProvider>()
      .toList();
});

/// Adapter for a specific connection id, or null if not found / unsupported.
final providerForConnectionProvider =
    Provider.family<GitProvider?, String>((ref, connectionId) {
  final providers = ref.watch(activeProvidersProvider);
  for (final p in providers) {
    if (p.connection.id == connectionId) return p;
  }
  return null;
});

/// Resolves the adapter that owns a given repo. Falls back to the first
/// connected provider of the same type (covers legacy repos with no
/// connectionId), then to any connected provider.
final providerForRepoProvider =
    Provider.family<GitProvider?, RepoEntity>((ref, repo) {
  final providers = ref.watch(activeProvidersProvider);
  if (providers.isEmpty) return null;
  if (repo.connectionId.isNotEmpty) {
    for (final p in providers) {
      if (p.connection.id == repo.connectionId) return p;
    }
  }
  for (final p in providers) {
    if (p.type == repo.provider) return p;
  }
  return providers.first;
});
