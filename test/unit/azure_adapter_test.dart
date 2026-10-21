import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/data/datasources/azure_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/repositories/azure_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/issue_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/repo_entity.dart';

const _connection = GitConnection(
  id: 'az-1',
  type: GitProviderType.azureDevOps,
  accountLogin: 'octo',
  token: 'pat-1',
  baseUrl: 'https://dev.azure.com/myorg',
);

AzureRepoRepositoryImpl _adapter(http.Client client) => AzureRepoRepositoryImpl(
      AzureRemoteDatasource(
          client: client, pat: 'pat-1', orgUrl: 'https://dev.azure.com/myorg'),
      _connection,
    );

final _repo = RepoEntity(
  id: 1,
  name: 'app',
  fullName: 'ProjectX/app',
  htmlUrl: '',
  stargazersCount: 0,
  forksCount: 0,
  watchersCount: 0,
  openIssuesCount: 0,
  isPrivate: true,
  isFork: false,
  updatedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2023, 1, 1),
  ownerLogin: 'ProjectX',
  ownerAvatarUrl: '',
  topics: const [],
  provider: GitProviderType.azureDevOps,
  connectionId: 'az-1',
  providerId: 'guid-1',
);

void main() {
  test('uses Basic auth with empty user and PAT', () async {
    http.Request? captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode({'value': []}), 200);
    });

    await _adapter(client).getRepos();

    final header = captured!.headers['Authorization']!;
    expect(header, startsWith('Basic '));
    expect(utf8.decode(base64.decode(header.substring(6))), ':pat-1');
  });

  test('getRepos maps GUID to providerId and project to ownerLogin', () async {
    final repoJson = {
      'value': [
        {
          'id': 'guid-1',
          'name': 'app',
          'project': {'name': 'ProjectX'},
          'defaultBranch': 'refs/heads/main',
          'webUrl': 'https://dev.azure.com/myorg/ProjectX/_git/app',
        }
      ]
    };
    final client =
        MockClient((_) async => http.Response(jsonEncode(repoJson), 200));

    final repos = await _adapter(client).getRepos();

    expect(repos.single.providerId, 'guid-1');
    expect(repos.single.ownerLogin, 'ProjectX');
    expect(repos.single.fullName, 'ProjectX/app');
    expect(repos.single.defaultBranch, 'main');
    expect(repos.single.provider, GitProviderType.azureDevOps);
  });

  test('getIssues runs WIQL then fetches work items', () async {
    final calls = <String>[];
    final client = MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.url.path.contains('/wiql')) {
        return http.Response(
            jsonEncode({
              'workItems': [
                {'id': 42}
              ]
            }),
            200);
      }
      if (req.url.path.contains('/workitems')) {
        return http.Response(
            jsonEncode({
              'value': [
                {
                  'id': 42,
                  'fields': {
                    'System.Title': 'Fix login',
                    'System.State': 'Active',
                    'System.WorkItemType': 'Bug',
                    'System.CreatedBy': {'displayName': 'Dana'},
                    'System.CreatedDate': '2024-01-01T00:00:00Z',
                    'System.ChangedDate': '2024-01-02T00:00:00Z',
                  }
                }
              ]
            }),
            200);
      }
      return http.Response('{}', 200);
    });

    final issues = await _adapter(client).getIssues(_repo, state: 'open');

    expect(issues.single.number, 42);
    expect(issues.single.title, 'Fix login');
    expect(issues.single.state, IssueState.open);
    expect(issues.single.labels.single.name, 'Bug');
    expect(calls.any((c) => c.startsWith('POST') && c.contains('wiql')), isTrue);
    expect(calls.any((c) => c.contains('workitems')), isTrue);
  });

  test('capabilities expose work items, not issues', () {
    final caps =
        _adapter(MockClient((_) async => http.Response('{}', 200))).capabilities;
    expect(caps.workItems, isTrue);
    expect(caps.issues, isFalse);
    expect(caps.pullRequests, isTrue);
  });
}
