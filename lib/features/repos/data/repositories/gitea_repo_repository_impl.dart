import '../../../../core/git/git_provider_type.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../auth/domain/git_connection.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/item_detail_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../datasources/gitea_remote_datasource.dart';
import 'inbox_only_provider.dart';
import '../../../../core/utils/url_path.dart';

/// Gitea / Forgejo / Codeberg adapter: Inbox, in-app detail and PR actions.
/// The repository browser is not implemented for this provider yet.
class GiteaRepoRepositoryImpl extends InboxOnlyProvider {
  final GiteaRemoteDatasource _ds;
  @override
  final GitConnection connection;

  GiteaRepoRepositoryImpl(this._ds, this.connection);

  @override
  GitProviderType get type => GitProviderType.gitea;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        inbox: true,
        itemDetail: true,
        approvePullRequests: true,
        requestChanges: true,
        mergePullRequests: true,
      );

  static DateTime _date(dynamic v) =>
      v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();

  @override
  Future<UserEntity> getUser() async {
    final j = await _ds.getUserJson();
    return UserEntity(
      login: j['login'] as String? ?? '',
      name: j['full_name'] as String?,
      avatarUrl: j['avatar_url'] as String? ?? '',
      publicRepos: 0,
      followers: 0,
      following: 0,
    );
  }

  // ─── Inbox ──────────────────────────────────────────────────────────────────
  InboxItem? _fromSearch(Map<String, dynamic> j, List<InboxReason> reasons) {
    final number = j['number'];
    final repo = (j['repository'] as Map?)?['full_name'] as String?;
    if (number is! int || repo == null) return null;
    return InboxItem(
      connectionId: connection.id,
      provider: GitProviderType.gitea,
      accountLogin: connection.accountLogin,
      kind: j['pull_request'] != null
          ? InboxItemKind.pullRequest
          : InboxItemKind.issue,
      repoFullName: repo,
      number: number,
      title: j['title'] as String? ?? '',
      htmlUrl: j['html_url'] as String? ?? '',
      updatedAt: _date(j['updated_at']),
      authorLogin: (j['user'] as Map?)?['login'] as String?,
      reasons: reasons,
    );
  }

  Future<List<Map<String, dynamic>>> _search(String query) async =>
      ((await _ds.send('GET', '/repos/issues/search?state=open&limit=50&$query'))
              as List)
          .cast<Map<String, dynamic>>();

  Future<List<InboxItem>> Function() _query(String query, InboxReason reason) =>
      () async => (await _search(query))
          .map((j) => _fromSearch(j, [reason]))
          .whereType<InboxItem>()
          .toList();

  /// My open PRs that need work: failing CI, conflicts or requested changes.
  Future<List<InboxItem>> _myPrsNeedingWork() async {
    final mine = (await _search('type=pulls&created=true')).take(15).toList();
    final out = await Future.wait(mine.map((j) async {
      final repo = (j['repository'] as Map?)?['full_name'] as String?;
      final n = j['number'];
      if (repo == null || n is! int) return null;
      final reasons = <InboxReason>[];
      try {
        final pr = await _ds.send('GET', '/repos/$repo/pulls/$n')
            as Map<String, dynamic>;
        if (pr['mergeable'] == false) reasons.add(InboxReason.conflicts);
        final sha = (pr['head'] as Map?)?['sha'] as String?;
        if (sha != null) {
          final st = await _ds.send('GET', '/repos/$repo/commits/$sha/status')
              as Map<String, dynamic>;
          final state = st['state'];
          if (state == 'failure' || state == 'error') {
            reasons.add(InboxReason.ciFailed);
          }
        }
        final reviews = await _ds.send('GET', '/repos/$repo/pulls/$n/reviews')
            as List;
        // Latest non-dismissed verdict per reviewer.
        final latest = <String, String>{};
        for (final r in reviews.cast<Map<String, dynamic>>()) {
          final state = r['state'] as String? ?? '';
          if (r['dismissed'] == true ||
              state == 'COMMENT' ||
              state == 'PENDING') {
            continue;
          }
          latest[(r['user'] as Map?)?['login'] as String? ?? '?'] = state;
        }
        if (latest.values.contains('REQUEST_CHANGES')) {
          reasons.add(InboxReason.changesRequested);
        }
      } on Exception {
        return null; // one broken PR must not hide the others
      }
      return reasons.isEmpty ? null : _fromSearch(j, reasons);
    }));
    return out.whereType<InboxItem>().toList();
  }

  @override
  Future<InboxBatch> getInboxItems() => collectInbox([
        _query('type=pulls&review_requested=true', InboxReason.reviewRequested),
        _query('assigned=true', InboxReason.assigned),
        _query('mentioned=true', InboxReason.mentioned),
        _myPrsNeedingWork,
      ]);

  // ─── Actions ────────────────────────────────────────────────────────────────
  @override
  Future<void> performPrAction(InboxItem item, PrAction action,
      {String? comment}) async {
    final base = '/repos/${encodePath(item.repoFullName)}/pulls/${item.number}';
    switch (action) {
      case PrAction.approve:
        await _ds.send('POST', '$base/reviews', body: {
          'event': 'APPROVED',
          if (comment != null && comment.isNotEmpty) 'body': comment,
        });
      case PrAction.requestChanges:
        if (comment == null || comment.trim().isEmpty) {
          throw const GitHubApiException(
              'A comment is required to request changes.');
        }
        await _ds.send('POST', '$base/reviews',
            body: {'event': 'REQUEST_CHANGES', 'body': comment});
      case PrAction.merge:
        await _ds.send('POST', '$base/merge', body: {'Do': 'merge'});
      case PrAction.rerunCi:
        throw UnsupportedProviderOperation(type, 're-run CI');
    }
  }

  // ─── Detail ─────────────────────────────────────────────────────────────────
  @override
  Future<ItemDetail> getItemDetail(InboxItem item) async {
    final repo = '/repos/${encodePath(item.repoFullName)}';
    final isPr = item.kind == InboxItemKind.pullRequest;
    final main = await _ds.send(
            'GET', isPr ? '$repo/pulls/${item.number}' : '$repo/issues/${item.number}')
        as Map<String, dynamic>;
    final commentsRaw =
        await _ds.send('GET', '$repo/issues/${item.number}/comments') as List;

    var files = const <DiffFile>[];
    if (isPr) {
      try {
        files = parseGitDiff(await _ds.getText('$repo/pulls/${item.number}.diff'));
      } on Exception {
        // Diff is a bonus; the rest of the detail still shows.
      }
    }

    final user = main['user'] as Map<String, dynamic>? ?? const {};
    final merged = main['merged'] == true;
    final title = main['title'] as String? ?? item.title;
    return ItemDetail(
      title: title,
      body: main['body'] as String? ?? '',
      authorLogin: user['login'] as String? ?? '',
      authorAvatarUrl: user['avatar_url'] as String?,
      state: merged
          ? 'merged'
          : main['state'] == 'closed'
              ? 'closed'
              : (isPr && RegExp(r'^(WIP|Draft)[:\s]', caseSensitive: false)
                      .hasMatch(title))
                  ? 'draft'
                  : 'open',
      createdAt: _date(main['created_at']),
      headBranch: (main['head'] as Map?)?['ref'] as String?,
      baseBranch: (main['base'] as Map?)?['ref'] as String?,
      files: files,
      comments: commentsRaw.cast<Map<String, dynamic>>().map((c) {
        final u = c['user'] as Map<String, dynamic>? ?? const {};
        return DetailComment(
          authorLogin: u['login'] as String? ?? '',
          authorAvatarUrl: u['avatar_url'] as String?,
          body: c['body'] as String? ?? '',
          createdAt: _date(c['created_at']),
        );
      }).toList(),
    );
  }
}
