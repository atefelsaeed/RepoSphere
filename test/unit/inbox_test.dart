import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repo_sphere/core/git/git_provider_type.dart';
import 'package:repo_sphere/features/auth/domain/git_connection.dart';
import 'package:repo_sphere/features/repos/data/datasources/gitlab_remote_datasource.dart';
import 'package:repo_sphere/features/repos/data/repositories/gitlab_repo_repository_impl.dart';
import 'package:repo_sphere/features/repos/domain/entities/inbox_item_entity.dart';

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
            jsonEncode([mr(2, status: 'ci_must_pass'), mr(3, status: 'mergeable')]),
            200);
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

    final items = await adapter.getInboxItems();

    expect(items.map((i) => i.number), [2, 1, 5]);
    expect(items[0].primaryReason, InboxReason.ciFailed);
    expect(items[1].primaryReason, InboxReason.reviewRequested);
    expect(items[2].kind, InboxItemKind.issue);
    expect(items[2].repoFullName, 'g/p');
  });
}
