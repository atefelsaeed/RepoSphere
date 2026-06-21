import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/data/datasources/gitlab_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/repositories/gitlab_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/pull_request_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/repo_entity.dart';

const _connection = GitConnection(
  id: 'gl-1',
  type: GitProviderType.gitlab,
  accountLogin: 'alice',
  token: 'glpat-xyz',
);

GitLabRepoRepositoryImpl _adapter(http.Client client) =>
    GitLabRepoRepositoryImpl(
      GitLabRemoteDatasource(client: client, token: 'glpat-xyz'),
      _connection,
    );

final _project = {
  'id': 99,
  'name': 'app',
  'path_with_namespace': 'alice/app',
  'description': 'desc',
  'web_url': 'https://gitlab.com/alice/app',
  'star_count': 3,
  'forks_count': 1,
  'open_issues_count': 2,
  'visibility': 'private',
  'last_activity_at': '2024-01-01T00:00:00Z',
  'created_at': '2023-01-01T00:00:00Z',
  'namespace': {'path': 'alice', 'avatar_url': ''},
  'default_branch': 'main',
  'topics': <dynamic>[],
};

final _repo = RepoEntity(
  id: 99,
  name: 'app',
  fullName: 'alice/app',
  htmlUrl: 'https://gitlab.com/alice/app',
  stargazersCount: 0,
  forksCount: 0,
  watchersCount: 0,
  openIssuesCount: 0,
  isPrivate: true,
  isFork: false,
  updatedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2023, 1, 1),
  ownerLogin: 'alice',
  ownerAvatarUrl: '',
  topics: const [],
  provider: GitProviderType.gitlab,
  connectionId: 'gl-1',
);

void main() {
  test('uses Bearer auth and gitlab.com base by default', () async {
    http.Request? captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode([_project]), 200);
    });

    await _adapter(client).getRepos();

    expect(captured?.headers['Authorization'], 'Bearer glpat-xyz');
    expect(captured?.url.toString(), startsWith('https://gitlab.com/api/v4'));
  });

  test('getRepos maps project and stamps connection', () async {
    final client =
        MockClient((_) async => http.Response(jsonEncode([_project]), 200));

    final repos = await _adapter(client).getRepos();

    expect(repos.length, 1);
    expect(repos.first.provider, GitProviderType.gitlab);
    expect(repos.first.connectionId, 'gl-1');
    expect(repos.first.fullName, 'alice/app');
  });

  test('getPullRequests maps GitLab merged state to PrState.merged', () async {
    final mr = {
      'iid': 7,
      'title': 'Add feature',
      'state': 'merged',
      'description': 'body',
      'web_url': 'https://gitlab.com/alice/app/-/merge_requests/7',
      'author': {'username': 'bob', 'avatar_url': ''},
      'source_branch': 'feat',
      'target_branch': 'main',
      'labels': <dynamic>[],
      'user_notes_count': 4,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-02T00:00:00Z',
      'merged_at': '2024-01-03T00:00:00Z',
    };
    Uri? capturedUri;
    final client = MockClient((req) async {
      capturedUri = req.url;
      return http.Response(jsonEncode([mr]), 200);
    });

    final prs = await _adapter(client).getPullRequests(_repo, state: 'open');

    expect(prs.single.state, PrState.merged);
    expect(prs.single.number, 7);
    expect(prs.single.headBranch, 'feat');
    // GitHub-style 'open' maps to GitLab 'opened'
    expect(capturedUri?.queryParameters['state'], 'opened');
  });

  test('honours a self-hosted base URL', () async {
    http.Request? captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode([_project]), 200);
    });
    final adapter = GitLabRepoRepositoryImpl(
      GitLabRemoteDatasource(
          client: client,
          token: 't',
          baseUrl: 'https://gitlab.mycorp.com'),
      _connection,
    );

    await adapter.getRepos();

    expect(captured?.url.toString(),
        startsWith('https://gitlab.mycorp.com/api/v4'));
  });

  test('capabilities mark issues and PRs supported, gists not', () {
    final caps = _adapter(MockClient((_) async => http.Response('[]', 200)))
        .capabilities;
    expect(caps.issues, isTrue);
    expect(caps.pullRequests, isTrue);
    expect(caps.gists, isFalse);
  });
}
