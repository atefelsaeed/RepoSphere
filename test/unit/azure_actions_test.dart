import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/data/datasources/azure_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/repositories/azure_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';

const _org = 'https://dev.azure.com/acme';

InboxItem _item({bool pr = true, String repo = 'Shop/web', int n = 7}) => InboxItem(
      connectionId: 'az',
      provider: GitProviderType.azureDevOps,
      accountLogin: 'me',
      kind: pr ? InboxItemKind.pullRequest : InboxItemKind.issue,
      repoFullName: repo,
      number: n,
      title: 'Fallback',
      htmlUrl: 'u',
      updatedAt: DateTime(2024),
      reasons: const [InboxReason.reviewRequested],
    );

AzureRepoRepositoryImpl _adapter(http.Client c) => AzureRepoRepositoryImpl(
      AzureRemoteDatasource(client: c, pat: 'p', orgUrl: _org),
      const GitConnection(
        id: 'az',
        type: GitProviderType.azureDevOps,
        accountLogin: 'me',
        token: 'p',
        baseUrl: _org,
      ),
    );

http.Response _json(Object o) => http.Response(jsonEncode(o), 200);

void main() {
  test('capabilities advertise what is implemented', () {
    final c = _adapter(MockClient((_) async => _json({}))).capabilities;
    expect(c.itemDetail && c.approvePullRequests && c.requestChanges, isTrue);
    expect(c.mergePullRequests, isTrue);
    expect(c.rerunCi, isFalse);
  });

  group('actions', () {
    late List<String> calls;
    late Map<String, dynamic> lastBody;

    MockClient client() => MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          if (req.body.isNotEmpty) lastBody = jsonDecode(req.body) as Map<String, dynamic>;
          if (req.url.path.endsWith('/connectionData')) {
            return _json({'authenticatedUser': {'id': 'me-id'}});
          }
          if (req.method == 'GET' && req.url.path.endsWith('/pullrequests/7')) {
            return _json({'lastMergeSourceCommit': {'commitId': 'abc123'}});
          }
          return _json({});
        });

    setUp(() {
      calls = [];
      lastBody = {};
    });

    test('approve votes 10 as the signed-in user', () async {
      await _adapter(client()).performPrAction(_item(), PrAction.approve);

      expect(calls.last,
          'PUT /acme/Shop/_apis/git/repositories/web/pullrequests/7/reviewers/me-id');
      expect(lastBody['vote'], 10);
    });

    test('request changes needs a comment, then posts a thread and votes -5',
        () async {
      final a = _adapter(client());
      expect(a.performPrAction(_item(), PrAction.requestChanges),
          throwsA(isA<GitHubApiException>()));

      await a.performPrAction(_item(), PrAction.requestChanges, comment: 'Please fix X');

      expect(calls.where((c) => c.contains('/threads')).length, 1);
      expect(calls.last, endsWith('/reviewers/me-id'));
      expect(lastBody['vote'], -5);
    });

    test('merge completes the PR against its latest source commit', () async {
      await _adapter(client()).performPrAction(_item(), PrAction.merge);

      expect(calls.last, 'PATCH /acme/Shop/_apis/git/repositories/web/pullrequests/7');
      expect(lastBody['status'], 'completed');
      expect((lastBody['lastMergeSourceCommit'] as Map)['commitId'], 'abc123');
    });

    test('re-run CI and work-item actions are unsupported', () async {
      final a = _adapter(client());
      expect(a.performPrAction(_item(), PrAction.rerunCi),
          throwsA(isA<UnsupportedProviderOperation>()));
      expect(a.performPrAction(_item(pr: false), PrAction.approve),
          throwsA(isA<UnsupportedProviderOperation>()));
    });
  });

  group('detail', () {
    test('PR: state, branches, changed files and human comments only', () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/pullrequests/7')) {
          return _json({
            'title': 'Add cart',
            'description': 'Adds a cart',
            'status': 'completed',
            'creationDate': '2024-01-01T00:00:00Z',
            'sourceRefName': 'refs/heads/feat/cart',
            'targetRefName': 'refs/heads/main',
            'createdBy': {'displayName': 'Bob'},
          });
        }
        if (p.endsWith('/iterations')) {
          return _json({'value': [{'id': 1}, {'id': 2}]});
        }
        if (p.endsWith('/iterations/2/changes')) {
          return _json({
            'changeEntries': [
              {'changeType': 'add', 'item': {'path': '/lib/cart.dart'}},
              {'changeType': 'edit', 'item': {'path': '/README.md'}},
              {'changeType': 'delete', 'item': {'path': '/old.txt'}},
              {'changeType': 'edit', 'item': {'path': '/lib', 'isFolder': true}},
            ]
          });
        }
        if (p.endsWith('/threads')) {
          return _json({
            'value': [
              {
                'comments': [
                  {'commentType': 'system', 'content': 'Policy ran', 'author': {'displayName': 'bot'}, 'publishedDate': '2024-01-02T00:00:00Z'},
                  {'commentType': 'text', 'content': 'Looks good', 'author': {'displayName': 'Amy'}, 'publishedDate': '2024-01-03T00:00:00Z'},
                ]
              }
            ]
          });
        }
        return _json({});
      });

      final d = await _adapter(client).getItemDetail(_item());

      expect(d.state, 'merged');
      expect(d.headBranch, 'feat/cart');
      expect(d.baseBranch, 'main');
      expect(d.files.map((f) => '${f.status}:${f.path}'),
          ['added:lib/cart.dart', 'modified:README.md', 'removed:old.txt']);
      expect(d.comments.map((c) => c.body), ['Looks good']);
    });

    test('PR: a failing changed-files call does not hide the rest', () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/pullrequests/7')) {
          return _json({'title': 'T', 'status': 'active', 'creationDate': '2024-01-01T00:00:00Z'});
        }
        if (p.contains('/iterations')) return http.Response('boom', 500);
        return _json({'value': []});
      });

      final d = await _adapter(client).getItemDetail(_item());
      expect(d.title, 'T');
      expect(d.state, 'open');
      expect(d.files, isEmpty);
    });

    test('work item: HTML description becomes plain text; closed state mapped',
        () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/workitems/42')) {
          return _json({
            'fields': {
              'System.Title': 'Fix login',
              'System.Description': '<div>Users can&#39;t <b>log in</b>&nbsp;on Safari</div><br>Steps &amp; notes',
              'System.State': 'Done',
              'System.CreatedBy': {'displayName': 'Bob'},
              'System.CreatedDate': '2024-01-01T00:00:00Z',
            }
          });
        }
        if (p.endsWith('/comments')) {
          return _json({
            'comments': [
              {'text': '<p>On it</p>', 'createdBy': {'displayName': 'Amy'}, 'createdDate': '2024-01-02T00:00:00Z'}
            ]
          });
        }
        return _json({});
      });

      final d = await _adapter(client)
          .getItemDetail(_item(pr: false, repo: 'Shop', n: 42));

      expect(d.state, 'closed');
      expect(d.body, "Users can't log in on Safari\n\nSteps & notes");
      expect(d.comments.single.body, 'On it');
      expect(d.files, isEmpty);
    });
  });

  test('htmlToPlain handles null and collapses blank lines', () {
    expect(AzureRepoRepositoryImpl.htmlToPlain(null), '');
    expect(AzureRepoRepositoryImpl.htmlToPlain('<p>a</p><p></p><p></p><p>b</p>'), 'a\n\nb');
  });
}
