import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/data/datasources/github_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/datasources/gitlab_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/repositories/github_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/data/repositories/gitlab_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';
import 'package:repo_sphere/features/repos/domain/entities/item_detail_entity.dart';

InboxItem _item(GitProviderType t, {bool pr = true, String repo = 'o/r', int n = 5}) =>
    InboxItem(
      connectionId: 'c',
      provider: t,
      accountLogin: 'me',
      kind: pr ? InboxItemKind.pullRequest : InboxItemKind.issue,
      repoFullName: repo,
      number: n,
      title: 'Fallback',
      htmlUrl: 'u',
      updatedAt: DateTime(2024),
      reasons: const [InboxReason.assigned],
    );

void main() {
  group('diff helpers', () {
    test('classifies unified diff lines', () {
      expect(classifyDiffLine('@@ -1,2 +1,3 @@'), DiffLineKind.hunk);
      expect(classifyDiffLine('+added'), DiffLineKind.added);
      expect(classifyDiffLine('-removed'), DiffLineKind.removed);
      expect(classifyDiffLine(' context'), DiffLineKind.context);
      // file headers are not content lines
      expect(classifyDiffLine('+++ b/file'), DiffLineKind.context);
      expect(classifyDiffLine('--- a/file'), DiffLineKind.context);
    });

    test('countDiff counts only content lines', () {
      const patch = '@@ -1,3 +1,4 @@\n a\n-b\n+c\n+d\n e';
      final c = countDiff(patch);
      expect((c.additions, c.deletions), (2, 1));
      expect(countDiff(null).additions, 0);
    });
  });

  group('GitHub detail', () {
    GitHubRepoRepositoryImpl adapter(http.Client c) => GitHubRepoRepositoryImpl(
        GitHubRemoteDatasource(client: c, token: 't'),
        const GitConnection(
            id: 'c', type: GitProviderType.github, accountLogin: 'me', token: 't'));

    test('maps a merged PR with files and comments', () async {
      final seen = <String>[];
      final client = MockClient((req) async {
        seen.add(req.url.path);
        if (req.url.path.endsWith('/pulls/5')) {
          return http.Response(
              jsonEncode({
                'title': 'Add feature',
                'body': 'Does a thing',
                'user': {'login': 'bob', 'avatar_url': 'a'},
                'state': 'closed',
                'merged': true,
                'created_at': '2024-01-01T00:00:00Z',
                'head': {'ref': 'feat'},
                'base': {'ref': 'main'},
              }),
              200);
        }
        if (req.url.path.endsWith('/pulls/5/files')) {
          return http.Response(
              jsonEncode([
                {
                  'filename': 'lib/a.dart',
                  'status': 'modified',
                  'additions': 2,
                  'deletions': 1,
                  'patch': '@@ -1 +1,2 @@\n-a\n+b\n+c'
                },
                {'filename': 'img.png', 'status': 'added', 'additions': 0, 'deletions': 0},
              ]),
              200);
        }
        return http.Response(
            jsonEncode([
              {
                'user': {'login': 'amy'},
                'body': 'LGTM',
                'created_at': '2024-01-02T00:00:00Z'
              }
            ]),
            200);
      });

      final d = await adapter(client).getItemDetail(_item(GitProviderType.github));

      expect(d.state, 'merged');
      expect(d.headBranch, 'feat');
      expect(d.files.length, 2);
      expect(d.files.last.patch, isNull); // binary: no patch
      expect((d.additions, d.deletions), (2, 1));
      expect(d.comments.single.authorLogin, 'amy');
      expect(seen, contains('/repos/o/r/pulls/5/files'));
    });

    test('an issue has no files and uses the issues endpoint', () async {
      final seen = <String>[];
      final client = MockClient((req) async {
        seen.add(req.url.path);
        if (req.url.path.endsWith('/issues/5')) {
          return http.Response(
              jsonEncode({
                'title': 'Bug',
                'body': null,
                'user': {'login': 'bob'},
                'state': 'open',
                'created_at': '2024-01-01T00:00:00Z',
              }),
              200);
        }
        return http.Response('[]', 200);
      });

      final d = await adapter(client)
          .getItemDetail(_item(GitProviderType.github, pr: false));

      expect(d.files, isEmpty);
      expect(d.body, '');
      expect(d.state, 'open');
      expect(seen.any((p) => p.contains('/pulls/')), isFalse);
    });
  });

  group('GitLab detail', () {
    GitLabRepoRepositoryImpl adapter(http.Client c) => GitLabRepoRepositoryImpl(
        GitLabRemoteDatasource(client: c, token: 't'),
        const GitConnection(
            id: 'c', type: GitProviderType.gitlab, accountLogin: 'me', token: 't'));

    Map<String, dynamic> mr() => {
          'title': 'MR title',
          'description': 'desc',
          'author': {'username': 'bob'},
          'state': 'opened',
          'created_at': '2024-01-01T00:00:00Z',
          'source_branch': 'feat',
          'target_branch': 'main',
        };

    test('maps diffs and hides system notes', () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/merge_requests/5')) return http.Response(jsonEncode(mr()), 200);
        if (p.endsWith('/merge_requests/5/diffs')) {
          return http.Response(
              jsonEncode([
                {
                  'new_path': 'a.rb',
                  'old_path': 'a.rb',
                  'new_file': true,
                  'diff': '@@ -0,0 +1,2 @@\n+x\n+y'
                }
              ]),
              200);
        }
        return http.Response(
            jsonEncode([
              {'system': true, 'body': 'added 1 commit', 'author': {'username': 'bot'}, 'created_at': '2024-01-02T00:00:00Z'},
              {'system': false, 'body': 'Looks good', 'author': {'username': 'amy'}, 'created_at': '2024-01-03T00:00:00Z'},
            ]),
            200);
      });

      final d = await adapter(client).getItemDetail(_item(GitProviderType.gitlab, repo: 'g/p'));

      expect(d.state, 'open');
      expect(d.files.single.status, 'added');
      expect(d.additions, 2);
      expect(d.comments.map((c) => c.body), ['Looks good']);
    });

    test('falls back to /changes on older GitLab', () async {
      final client = MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/merge_requests/5')) return http.Response(jsonEncode(mr()), 200);
        if (p.endsWith('/diffs')) return http.Response('{}', 404);
        if (p.endsWith('/changes')) {
          return http.Response(
              jsonEncode({
                'changes': [
                  {'new_path': 'b.rb', 'diff': '@@ -1 +1 @@\n-1\n+2'}
                ]
              }),
              200);
        }
        return http.Response('[]', 200);
      });

      final d = await adapter(client).getItemDetail(_item(GitProviderType.gitlab, repo: 'g/p'));

      expect(d.files.single.path, 'b.rb');
      expect((d.additions, d.deletions), (1, 1));
    });
  });
}
