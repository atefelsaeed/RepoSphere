import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/core/utils/exceptions.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/data/datasources/gitea_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/git_provider_factory.dart';
import 'package:repo_sphere/features/repos/data/repositories/gitea_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/item_detail_entity.dart';
import 'package:repo_sphere/features/repos/domain/repositories/git_provider.dart';

const _conn = GitConnection(
  id: 'gt',
  type: GitProviderType.gitea,
  accountLogin: 'me',
  token: 'tok',
  baseUrl: 'https://codeberg.org',
);

GiteaRepoRepositoryImpl _adapter(http.Client c) => GiteaRepoRepositoryImpl(
    GiteaRemoteDatasource(client: c, token: 'tok', baseUrl: 'https://codeberg.org'),
    _conn);

http.Response _json(Object o) => http.Response(jsonEncode(o), 200);

InboxItem _item({bool pr = true, int n = 3}) => InboxItem(
      connectionId: 'gt',
      provider: GitProviderType.gitea,
      accountLogin: 'me',
      kind: pr ? InboxItemKind.pullRequest : InboxItemKind.issue,
      repoFullName: 'org/app',
      number: n,
      title: 'Fallback',
      htmlUrl: 'u',
      updatedAt: DateTime(2024),
      reasons: const [InboxReason.reviewRequested],
    );

Map<String, dynamic> _hit(int n, {bool pr = true}) => {
      'number': n,
      'title': 'Item $n',
      'html_url': 'https://codeberg.org/org/app/pulls/$n',
      'updated_at': '2024-01-05T00:00:00Z',
      'repository': {'full_name': 'org/app'},
      'user': {'login': 'bob'},
      if (pr) 'pull_request': {'merged': false},
    };

void main() {
  test('uses token auth against /api/v1 and normalises the base URL', () async {
    http.Request? seen;
    final c = MockClient((req) async {
      seen = req;
      return _json({'login': 'me'});
    });
    final ds = GiteaRemoteDatasource(
        client: c, token: 'tok', baseUrl: 'https://git.example.org///');

    expect(await ds.verifyToken(), 'me');
    expect(seen!.url.toString(), 'https://git.example.org/api/v1/user');
    expect(seen!.headers['Authorization'], 'token tok');
  });

  test('factory builds the adapter only when a server URL is set', () {
    final client = MockClient((_) async => _json({}));
    expect(buildGitProvider(_conn, client), isA<GiteaRepoRepositoryImpl>());
    expect(
        buildGitProvider(
            const GitConnection(
                id: 'x', type: GitProviderType.gitea, accountLogin: 'a', token: 't'),
            client),
        isNull);
  });

  test('browser reads are empty, not errors (inbox-only provider)', () async {
    final a = _adapter(MockClient((_) async => _json({})));
    expect(await a.getRepos(), isEmpty);
    expect(await a.getNotifications(), isEmpty);
    expect(a.capabilities.inbox && a.capabilities.itemDetail, isTrue);
    expect(a.capabilities.rerunCi, isFalse);
  });

  group('inbox', () {
    test('maps review requests, assignments, mentions and my PRs', () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        final q = req.url.queryParameters;
        if (p == '/api/v1/repos/issues/search') {
          if (q['review_requested'] == 'true') return _json([_hit(1)]);
          if (q['assigned'] == 'true') return _json([_hit(2, pr: false)]);
          if (q['mentioned'] == 'true') return _json([_hit(3)]);
          if (q['created'] == 'true') return _json([_hit(4), _hit(5)]);
        }
        if (p == '/api/v1/repos/org/app/pulls/4') {
          return _json({'mergeable': false, 'head': {'sha': 's4'}});
        }
        if (p == '/api/v1/repos/org/app/pulls/5') {
          return _json({'mergeable': true, 'head': {'sha': 's5'}});
        }
        if (p.endsWith('/commits/s4/status')) return _json({'state': 'failure'});
        if (p.endsWith('/commits/s5/status')) return _json({'state': 'success'});
        if (p.endsWith('/pulls/4/reviews')) {
          return _json([
            {'state': 'REQUEST_CHANGES', 'user': {'login': 'amy'}, 'dismissed': false},
            {'state': 'APPROVED', 'user': {'login': 'zed'}},
          ]);
        }
        if (p.endsWith('/pulls/5/reviews')) {
          return _json([
            // amy asked for changes, then approved: latest verdict wins.
            {'state': 'REQUEST_CHANGES', 'user': {'login': 'amy'}},
            {'state': 'APPROVED', 'user': {'login': 'amy'}},
          ]);
        }
        return _json([]);
      });

      final batch = await _adapter(client).getInboxItems();
      final byNumber = {for (final i in batch.items) i.number: i};

      expect(batch.isPartial, isFalse);
      expect(byNumber[1]!.primaryReason, InboxReason.reviewRequested);
      expect(byNumber[2]!.kind, InboxItemKind.issue);
      expect(byNumber[2]!.primaryReason, InboxReason.assigned);
      expect(byNumber[3]!.primaryReason, InboxReason.mentioned);
      expect(byNumber[4]!.reasons, [
        InboxReason.ciFailed,
        InboxReason.changesRequested,
        InboxReason.conflicts,
      ]);
      expect(byNumber.containsKey(5), isFalse); // healthy PR is not an alert
      expect(byNumber[1]!.repoFullName, 'org/app');
    });

    test('one failing query is reported, the rest still load', () async {
      final client = MockClient((req) async {
        final q = req.url.queryParameters;
        if (q['mentioned'] == 'true') return http.Response('boom', 500);
        return _json(q['review_requested'] == 'true' ? [_hit(1)] : []);
      });

      final batch = await _adapter(client).getInboxItems();

      expect(batch.items.map((i) => i.number), [1]);
      expect(batch.isPartial, isTrue);
    });

    test('an expired token on every query surfaces as an error', () async {
      final client = MockClient((_) async => http.Response('', 401));
      expect(_adapter(client).getInboxItems(),
          throwsA(isA<GitHubAuthException>()));
    });
  });

  group('actions', () {
    late List<String> calls;
    late Map<String, dynamic> body;
    MockClient client() => MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          body = req.body.isEmpty ? {} : jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('', 200);
        });
    setUp(() => calls = []);

    test('approve and merge hit the right endpoints', () async {
      final a = _adapter(client());
      await a.performPrAction(_item(), PrAction.approve);
      expect(calls.last, 'POST /api/v1/repos/org/app/pulls/3/reviews');
      expect(body['event'], 'APPROVED');

      await a.performPrAction(_item(), PrAction.merge);
      expect(calls.last, 'POST /api/v1/repos/org/app/pulls/3/merge');
      expect(body['Do'], 'merge');
    });

    test('request changes needs a comment; re-run CI is unsupported', () async {
      final a = _adapter(client());
      expect(a.performPrAction(_item(), PrAction.requestChanges),
          throwsA(isA<GitHubApiException>()));
      await a.performPrAction(_item(), PrAction.requestChanges, comment: 'Fix it');
      expect(body['event'], 'REQUEST_CHANGES');
      expect(a.performPrAction(_item(), PrAction.rerunCi),
          throwsA(isA<UnsupportedProviderOperation>()));
    });
  });

  group('detail', () {
    const diff = '''
diff --git a/lib/a.dart b/lib/a.dart
index 111..222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,2 +1,3 @@
 keep
-old
+new
+more
diff --git a/img.png b/img.png
new file mode 100644
Binary files /dev/null and b/img.png differ
''';

    test('PR: merged state, diff files, comments', () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/pulls/3.diff')) return http.Response(diff, 200);
        if (p.endsWith('/pulls/3')) {
          return _json({
            'title': 'Add thing',
            'body': 'desc',
            'state': 'closed',
            'merged': true,
            'user': {'login': 'bob'},
            'created_at': '2024-01-01T00:00:00Z',
            'head': {'ref': 'feat'},
            'base': {'ref': 'main'},
          });
        }
        return _json([
          {'user': {'login': 'amy'}, 'body': 'LGTM', 'created_at': '2024-01-02T00:00:00Z'}
        ]);
      });

      final d = await _adapter(client).getItemDetail(_item());

      expect(d.state, 'merged');
      expect(d.headBranch, 'feat');
      expect(d.files.length, 2);
      expect((d.additions, d.deletions), (2, 1));
      expect(d.files.last.status, 'added');
      expect(d.files.last.patch, isNull);
      expect(d.comments.single.body, 'LGTM');
    });

    test('draft title prefix is recognised; a failing diff does not hide the rest',
        () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('.diff')) return http.Response('nope', 500);
        if (p.endsWith('/pulls/3')) {
          return _json({
            'title': 'WIP: later',
            'state': 'open',
            'user': {'login': 'bob'},
            'created_at': '2024-01-01T00:00:00Z',
          });
        }
        return _json([]);
      });

      final d = await _adapter(client).getItemDetail(_item());
      expect(d.state, 'draft');
      expect(d.files, isEmpty);
    });

    test('issue uses the issues endpoint and has no files', () async {
      final seen = <String>[];
      final client = MockClient((req) async {
        seen.add(req.url.path);
        if (req.url.path.endsWith('/issues/3')) {
          return _json({
            'title': 'Bug',
            'body': null,
            'state': 'open',
            'user': {'login': 'bob'},
            'created_at': '2024-01-01T00:00:00Z',
          });
        }
        return _json([]);
      });

      final d = await _adapter(client).getItemDetail(_item(pr: false));
      expect(d.files, isEmpty);
      expect(seen.any((p) => p.contains('/pulls/')), isFalse);
    });
  });

  group('parseGitDiff', () {
    test('handles renames, deletions and empty input', () {
      final files = parseGitDiff('''
diff --git a/old.txt b/new.txt
similarity index 90%
rename from old.txt
rename to new.txt
@@ -1 +1 @@
-a
+b
diff --git a/gone.txt b/gone.txt
deleted file mode 100644
@@ -1 +0,0 @@
-x
''');
      expect(files.map((f) => '${f.status}:${f.path}'),
          ['renamed:new.txt', 'removed:gone.txt']);
      expect(files.first.additions, 1);
      expect(parseGitDiff(''), isEmpty);
    });
  });
}
