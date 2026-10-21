import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/features/repos/data/datasources/azure_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/inbox_loader.dart';
import 'package:repo_sphere/features/repos/data/datasources/github_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/datasources/gitlab_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/repositories/azure_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/data/repositories/github_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/data/repositories/gitlab_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';

InboxItem _item(int n, List<InboxReason> reasons, {int day = 1}) => InboxItem(
      connectionId: 'c1',
      provider: GitProviderType.github,
      accountLogin: 'me',
      kind: InboxItemKind.pullRequest,
      repoFullName: 'me/app',
      number: n,
      title: 'PR $n',
      htmlUrl: 'https://x/$n',
      updatedAt: DateTime(2024, 1, day),
      reasons: reasons,
    );

void main() {
  group('InboxItem.mergeAndSort', () {
    test('merges duplicates and keeps every reason, most urgent first', () {
      final out = InboxItem.mergeAndSort([
        _item(1, [InboxReason.mentioned]),
        _item(1, [InboxReason.ciFailed]),
      ]);
      expect(out.length, 1);
      expect(out.first.reasons, [InboxReason.ciFailed, InboxReason.mentioned]);
    });

    test('sorts by urgency, then newest first', () {
      final out = InboxItem.mergeAndSort([
        _item(1, [InboxReason.mentioned], day: 9),
        _item(2, [InboxReason.reviewRequested], day: 1),
        _item(3, [InboxReason.reviewRequested], day: 5),
        _item(4, [InboxReason.ciFailed], day: 2),
      ]);
      expect(out.map((i) => i.number), [4, 3, 2, 1]);
    });
  });

  test('GitLab inbox maps review requests, own MR status and mentions',
      () async {
    Map<String, dynamic> mr(int iid, {String? status}) => {
          'iid': iid,
          'title': 'MR $iid',
          'web_url': 'https://gitlab.com/g/p/-/merge_requests/$iid',
          'updated_at': '2024-01-02T00:00:00Z',
          'references': {'full': 'g/p!$iid'},
          'author': {'username': 'bob'},
          if (status != null) 'detailed_merge_status': status,
        };

    final client = MockClient((req) async {
      final path = req.url.path;
      final q = req.url.queryParameters;
      if (path.endsWith('/todos')) {
        return http.Response(
            jsonEncode([
              {
                'action_name': 'mentioned',
                'target_type': 'Issue',
                'target_url': 'https://gitlab.com/g/p/-/issues/5',
                'updated_at': '2024-01-03T00:00:00Z',
                'target': {
                  'iid': 5,
                  'title': 'Issue 5',
                  'references': {'full': 'g/p#5'},
                },
              },
            ]),
            200);
      }
      if (path.endsWith('/merge_requests') &&
          q['reviewer_username'] == 'alice') {
        return http.Response(jsonEncode([mr(1)]), 200);
      }
      if (path.endsWith('/merge_requests') &&
          q['scope'] == 'created_by_me') {
        return http.Response(
            jsonEncode([
              {...mr(2, status: 'ci_must_pass'), 'project_id': 7},
              mr(3, status: 'mergeable'),
            ]),
            200);
      }
      if (path.endsWith('/projects/7/merge_requests/2')) {
        return http.Response(
            jsonEncode({'head_pipeline': {'status': 'failed'}}), 200);
      }
      return http.Response('[]', 200);
    });

    final adapter = GitLabRepoRepositoryImpl(
      GitLabRemoteDatasource(client: client, token: 't'),
      const GitConnection(
        id: 'gl-1',
        type: GitProviderType.gitlab,
        accountLogin: 'alice',
        token: 't',
      ),
    );

    final items = (await adapter.getInboxItems()).items;

    expect(items.map((i) => i.number), [2, 1, 5]);
    expect(items[0].primaryReason, InboxReason.ciFailed);
    expect(items[1].primaryReason, InboxReason.reviewRequested);
    expect(items[2].kind, InboxItemKind.issue);
    expect(items[2].repoFullName, 'g/p');
  });

  group('collectInbox', () {
    test('tolerates partial failure', () async {
      final out = await collectInbox([
        () async => [_item(1, [InboxReason.assigned])],
        () async => throw const GitHubApiException('boom'),
      ]);
      expect(out.items.length, 1);
      expect(out.isPartial, isTrue);
      expect(out.failures.length, 1);
    });

    test('rethrows when every query fails (no false "all clear")', () async {
      expect(
        collectInbox([
          () async => throw const GitHubAuthException('bad token'),
          () async => throw const GitHubApiException('boom'),
        ]),
        throwsA(isA<GitHubAuthException>()),
      );
    });
  });

  test('InboxItem JSON round-trips', () {
    final item = _item(7, [InboxReason.ciFailed, InboxReason.mentioned]);
    final back = InboxItem.fromJson(item.toJson());
    expect(back.key, item.key);
    expect(back.reasons, item.reasons);
    expect(back.updatedAt, item.updatedAt);
  });

  group('GitHub', () {
    const conn = GitConnection(
      id: 'gh-1',
      type: GitProviderType.github,
      accountLogin: 'me',
      token: 't',
    );

    GitHubRepoRepositoryImpl adapter(http.Client c) => GitHubRepoRepositoryImpl(
        GitHubRemoteDatasource(client: c, token: 't'), conn);

    test('inbox merges search hits with GraphQL PR status', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/graphql') {
          return http.Response(
              jsonEncode({
                'data': {
                  'search': {
                    'nodes': [
                      {
                        'number': 3,
                        'title': 'Mine',
                        'url': 'https://github.com/me/app/pull/3',
                        'updatedAt': '2024-01-05T00:00:00Z',
                        'repository': {'nameWithOwner': 'me/app'},
                        'mergeable': 'CONFLICTING',
                        'reviewDecision': 'CHANGES_REQUESTED',
                        'commits': {
                          'nodes': [
                            {
                              'commit': {
                                'statusCheckRollup': {'state': 'FAILURE'}
                              }
                            }
                          ]
                        },
                      },
                      {
                        'number': 4,
                        'title': 'Healthy',
                        'url': 'u',
                        'updatedAt': '2024-01-05T00:00:00Z',
                        'repository': {'nameWithOwner': 'me/app'},
                        'mergeable': 'MERGEABLE',
                        'reviewDecision': null,
                        'commits': {
                          'nodes': [
                            {
                              'commit': {
                                'statusCheckRollup': {'state': 'SUCCESS'}
                              }
                            }
                          ]
                        },
                      },
                    ]
                  }
                }
              }),
              200);
        }
        final q = req.url.queryParameters['q'] ?? '';
        final hit = {
          'number': 9,
          'title': 'Review me',
          'html_url': 'https://github.com/o/r/pull/9',
          'updated_at': '2024-01-04T00:00:00Z',
          'repository_url': 'https://api.github.com/repos/o/r',
          'pull_request': {},
          'user': {'login': 'bob'},
        };
        return http.Response(
            jsonEncode({
              'items': q.contains('review-requested') ? [hit] : []
            }),
            200);
      });

      final items = (await adapter(client).getInboxItems()).items;

      expect(items.map((i) => i.number), [3, 9]);
      expect(items[0].reasons, [
        InboxReason.ciFailed,
        InboxReason.changesRequested,
        InboxReason.conflicts,
      ]);
      expect(items[1].primaryReason, InboxReason.reviewRequested);
      expect(items[1].repoFullName, 'o/r');
    });

    test('approve posts an APPROVE review; request changes needs a comment',
        () async {
      http.Request? sent;
      final client = MockClient((req) async {
        sent = req;
        return http.Response('{}', 200);
      });
      final item = _item(5, [InboxReason.reviewRequested]);

      await adapter(client).performPrAction(item, PrAction.approve);
      expect(sent?.method, 'POST');
      expect(sent?.url.path, '/repos/me/app/pulls/5/reviews');
      expect(jsonDecode(sent!.body)['event'], 'APPROVE');

      expect(
        adapter(client).performPrAction(item, PrAction.requestChanges),
        throwsA(isA<GitHubApiException>()),
      );
    });

    test('rerunCi re-runs only failed workflow runs for the PR head', () async {
      final posts = <String>[];
      final client = MockClient((req) async {
        if (req.method == 'POST') {
          posts.add(req.url.path);
          return http.Response('', 201);
        }
        if (req.url.path.endsWith('/pulls/5')) {
          return http.Response(
              jsonEncode({'head': {'sha': 'abc'}}), 200);
        }
        return http.Response(
            jsonEncode({
              'workflow_runs': [
                {'id': 1, 'conclusion': 'failure'},
                {'id': 2, 'conclusion': 'success'},
              ]
            }),
            200);
      });

      await adapter(client)
          .performPrAction(_item(5, [InboxReason.ciFailed]), PrAction.rerunCi);

      expect(posts, ['/repos/me/app/actions/runs/1/rerun-failed-jobs']);
    });
  });

  test('GitLab approve/merge hit the MR endpoints; request changes unsupported',
      () async {
    final calls = <String>[];
    final client = MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      return http.Response('{}', 200);
    });
    final adapter = GitLabRepoRepositoryImpl(
      GitLabRemoteDatasource(client: client, token: 't'),
      const GitConnection(
          id: 'gl', type: GitProviderType.gitlab, accountLogin: 'a', token: 't'),
    );
    final item = _item(8, [InboxReason.reviewRequested]);

    await adapter.performPrAction(item, PrAction.approve);
    await adapter.performPrAction(item, PrAction.merge);

    expect(calls, [
      'POST /api/v4/projects/me%2Fapp/merge_requests/8/approve',
      'PUT /api/v4/projects/me%2Fapp/merge_requests/8/merge',
    ]);
    expect(adapter.performPrAction(item, PrAction.requestChanges),
        throwsA(isA<UnsupportedProviderOperation>()));
  });

  test('Azure inbox: unreviewed PRs, own PRs with rejections, work items',
      () async {
    final client = MockClient((req) async {
      final path = req.url.path;
      final q = req.url.queryParameters;
      if (path.endsWith('/connectionData')) {
        return http.Response(
            jsonEncode({'authenticatedUser': {'id': 'me-id'}}), 200);
      }
      if (path.endsWith('/_apis/git/repositories')) {
        return http.Response(
            jsonEncode({
              'value': [
                {'id': 'r1', 'project': {'name': 'Proj'}}
              ]
            }),
            200);
      }
      if (path.endsWith('/wit/wiql')) {
        return http.Response(
            jsonEncode({
              'workItems': [
                {'id': 11}
              ]
            }),
            200);
      }
      if (path.endsWith('/wit/workitems')) {
        return http.Response(
            jsonEncode({
              'value': [
                {
                  'id': 11,
                  'fields': {
                    'System.Title': 'Fix login',
                    'System.TeamProject': 'Proj',
                    'System.ChangedDate': '2024-01-02T00:00:00Z',
                  }
                }
              ]
            }),
            200);
      }
      Map<String, dynamic> pr(int id, List<Map<String, dynamic>> reviewers,
              {String? mergeStatus}) =>
          {
            'pullRequestId': id,
            'title': 'PR $id',
            'creationDate': '2024-01-03T00:00:00Z',
            'repository': {
              'name': 'repo',
              'project': {'name': 'Proj'}
            },
            'createdBy': {'displayName': 'Bob'},
            'reviewers': reviewers,
            if (mergeStatus != null) 'mergeStatus': mergeStatus,
          };
      if (q.containsKey('searchCriteria.reviewerId')) {
        return http.Response(
            jsonEncode({
              'value': [
                pr(1, [
                  {'id': 'me-id', 'vote': 0}
                ]),
                pr(2, [
                  {'id': 'me-id', 'vote': 10}
                ]),
              ]
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'value': [
              pr(3, [
                {'id': 'x', 'vote': -10}
              ]),
              pr(4, [
                {'id': 'x', 'vote': 10}
              ]),
            ]
          }),
          200);
    });

    final adapter = AzureRepoRepositoryImpl(
      AzureRemoteDatasource(
          client: client, pat: 'p', orgUrl: 'https://dev.azure.com/org'),
      const GitConnection(
        id: 'az',
        type: GitProviderType.azureDevOps,
        accountLogin: 'me',
        token: 'p',
        baseUrl: 'https://dev.azure.com/org',
      ),
    );

    final items = (await adapter.getInboxItems()).items;

    expect(items.map((i) => i.number), [3, 1, 11]);
    expect(items[0].primaryReason, InboxReason.changesRequested);
    expect(items[1].primaryReason, InboxReason.reviewRequested);
    expect(items[2].kind, InboxItemKind.issue);
    expect(items[1].htmlUrl,
        'https://dev.azure.com/org/Proj/_git/repo/pullrequest/1');
  });

  group('robustness', () {
    const conn = GitConnection(
      id: 'gh-1',
      type: GitProviderType.github,
      accountLogin: 'me',
      token: 't',
    );
    GitHubRepoRepositoryImpl gh(http.Client c) => GitHubRepoRepositoryImpl(
        GitHubRemoteDatasource(client: c, token: 't'), conn);

    Map<String, dynamic> hit(int n) => {
          'number': n,
          'title': 'PR $n',
          'html_url': 'https://github.com/o/r/pull/$n',
          'updated_at': '2024-01-04T00:00:00Z',
          'repository_url': 'https://api.github.com/repos/o/r',
          'pull_request': {},
          'user': {'login': 'bob'},
        };

    test('GitHub search follows pages beyond the first 100 results', () async {
      final pages = <String>[];
      final client = MockClient((req) async {
        if (req.url.path == '/graphql') {
          return http.Response(jsonEncode({'data': {'search': {'nodes': []}}}), 200);
        }
        final page = int.parse(req.url.queryParameters['page']!);
        final q = req.url.queryParameters['q']!;
        if (q.contains('review-requested')) pages.add('$page');
        final items = q.contains('review-requested')
            ? [for (var i = 0; i < (page == 1 ? 100 : 30); i++) hit(page * 1000 + i)]
            : <Map<String, dynamic>>[];
        return http.Response(jsonEncode({'total_count': 130, 'items': items}), 200);
      });

      final batch = await gh(client).getInboxItems();

      expect(pages, ['1', '2']);
      expect(batch.items.length, 130);
      expect(batch.isPartial, isFalse);
    });

    test('a secondary rate limit is reported, other results still shown',
        () async {
      final client = MockClient((req) async {
        if (req.url.path == '/graphql') {
          return http.Response(jsonEncode({'data': {'search': {'nodes': []}}}), 200);
        }
        final q = req.url.queryParameters['q']!;
        if (q.contains('mentions')) {
          return http.Response(
              jsonEncode({'message': 'You have exceeded a secondary rate limit.'}),
              403,
              headers: {'retry-after': '42'});
        }
        return http.Response(
            jsonEncode({
              'total_count': 1,
              'items': q.contains('review-requested') ? [hit(9)] : []
            }),
            200);
      });

      final batch = await gh(client).getInboxItems();

      expect(batch.items.map((i) => i.number), [9]);
      expect(batch.isPartial, isTrue);
      expect(inboxErrorText(batch.failures.first), contains('42s'));
    });

    test('GitLab: a running pipeline is not reported as CI failed', () async {
      final client = MockClient((req) async {
        final path = req.url.path;
        if (path.endsWith('/merge_requests') &&
            req.url.queryParameters['scope'] == 'created_by_me') {
          return http.Response(
              jsonEncode([
                {
                  'iid': 5,
                  'project_id': 3,
                  'title': 'MR 5',
                  'web_url': 'u',
                  'updated_at': '2024-01-02T00:00:00Z',
                  'references': {'full': 'g/p!5'},
                  'detailed_merge_status': 'ci_must_pass',
                }
              ]),
              200);
        }
        if (path.endsWith('/projects/3/merge_requests/5')) {
          return http.Response(
              jsonEncode({'head_pipeline': {'status': 'running'}}), 200);
        }
        return http.Response('[]', 200);
      });
      final adapter = GitLabRepoRepositoryImpl(
        GitLabRemoteDatasource(client: client, token: 't'),
        const GitConnection(
            id: 'gl', type: GitProviderType.gitlab, accountLogin: 'a', token: 't'),
      );

      expect((await adapter.getInboxItems()).items, isEmpty);
    });
  });
}
