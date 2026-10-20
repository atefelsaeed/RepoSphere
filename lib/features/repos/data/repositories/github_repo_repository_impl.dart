import '../../../../core/git/git_provider_type.dart';
import '../../../auth/domain/git_connection.dart';
import '../../domain/entities/activity_event_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/commit_detail_entity.dart';
import '../../domain/entities/commit_entity.dart';
import '../../domain/entities/contributor_entity.dart';
import '../../domain/entities/gist_entity.dart';
import '../../domain/entities/inbox_item_entity.dart';
import '../../domain/entities/issue_comment_entity.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/pull_request_entity.dart';
import '../../domain/entities/release_entity.dart';
import '../../domain/entities/repo_content_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../datasources/github_remote_datasource.dart';

/// GitHub adapter — wraps [GitHubRemoteDatasource] behind [GitProvider] and
/// stamps every repo with its originating [GitConnection].
class GitHubRepoRepositoryImpl implements GitProvider {
  final GitHubRemoteDatasource _ds;
  @override
  final GitConnection connection;

  const GitHubRepoRepositoryImpl(this._ds, this.connection);

  @override
  GitProviderType get type => GitProviderType.github;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        pullRequests: true,
        issues: true,
        releases: true,
        gists: true,
        notifications: true,
        activity: true,
        starring: true,
        fileTree: true,
        contributors: true,
        languages: true,
        search: true,
        writeComments: true,
        mergePullRequests: true,
        editIssueState: true,
        createIssues: true,
        inbox: true,
      );

  RepoEntity _stamp(RepoEntity r) =>
      r.copyWith(provider: GitProviderType.github, connectionId: connection.id);

  @override
  Future<UserEntity> getUser() async => (await _ds.getUser()).toEntity();

  @override
  Future<List<RepoEntity>> getRepos({int page = 1, int perPage = 100}) async {
    final models = await _ds.getRepos(page: page, perPage: perPage);
    return models.map((m) => _stamp(m.toEntity())).toList();
  }

  @override
  Future<List<RepoEntity>> getStarredRepos() async {
    final models = await _ds.getStarredRepos();
    return models.map((m) => _stamp(m.toEntity())).toList();
  }

  @override
  Future<List<RepoEntity>> searchRepos(String query,
      {int page = 1, int perPage = 30}) async {
    final models = await _ds.searchRepos(query, page: page, perPage: perPage);
    return models.map((m) => _stamp(m.toEntity())).toList();
  }

  @override
  Future<List<BranchEntity>> getBranches(RepoEntity repo) async {
    final models = await _ds.getBranches(repo.ownerLogin, repo.name);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CommitEntity>> getCommits(RepoEntity repo,
      {String? branch, int page = 1, int perPage = 30}) async {
    final models = await _ds.getCommits(repo.ownerLogin, repo.name,
        branch: branch, page: page, perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CommitDetailEntity> getCommitDetail(RepoEntity repo, String sha) =>
      _ds.getCommitDetail(repo.ownerLogin, repo.name, sha);

  @override
  Future<String?> getReadme(RepoEntity repo) =>
      _ds.getReadme(repo.ownerLogin, repo.name);

  @override
  Future<List<RepoContentItem>> getContents(RepoEntity repo, String path,
          {String? ref}) =>
      _ds.getContents(repo.ownerLogin, repo.name, path, ref: ref);

  @override
  Future<FileContent> getFileContent(RepoEntity repo, String path,
          {String? ref}) =>
      _ds.getFileContent(repo.ownerLogin, repo.name, path);

  @override
  Future<Map<String, int>> getLanguages(RepoEntity repo) =>
      _ds.getLanguages(repo.ownerLogin, repo.name);

  @override
  Future<List<ContributorEntity>> getContributors(RepoEntity repo,
      {int perPage = 8}) async {
    final models = await _ds.getContributors(repo.ownerLogin, repo.name,
        perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<PullRequestEntity>> getPullRequests(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30}) async {
    final models = await _ds.getPullRequests(repo.ownerLogin, repo.name,
        state: state, page: page, perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<IssueEntity>> getIssues(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30}) async {
    final models = await _ds.getIssues(repo.ownerLogin, repo.name,
        state: state, page: page, perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<IssueCommentEntity>> getIssueComments(
      RepoEntity repo, int number) async {
    final models =
        await _ds.getIssueComments(repo.ownerLogin, repo.name, number);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ReleaseEntity>> getReleases(RepoEntity repo,
      {int perPage = 10}) async {
    final models =
        await _ds.getReleases(repo.ownerLogin, repo.name, perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> isStarred(RepoEntity repo) =>
      _ds.isStarred(repo.ownerLogin, repo.name);

  @override
  Future<void> setStar(RepoEntity repo, bool starred) => starred
      ? _ds.starRepo(repo.ownerLogin, repo.name)
      : _ds.unstarRepo(repo.ownerLogin, repo.name);

  @override
  Future<IssueEntity> createIssue(RepoEntity repo,
      {required String title,
      String? body,
      List<String> labels = const []}) async {
    final model = await _ds.createIssue(repo.ownerLogin, repo.name,
        title: title, body: body, labels: labels);
    return model.toEntity();
  }

  @override
  Future<IssueCommentEntity> addIssueComment(
      RepoEntity repo, int number, String body) async {
    final model =
        await _ds.addIssueComment(repo.ownerLogin, repo.name, number, body);
    return model.toEntity();
  }

  @override
  Future<void> mergePullRequest(RepoEntity repo, int number) =>
      _ds.mergePullRequest(repo.ownerLogin, repo.name, number);

  @override
  Future<void> setIssueState(RepoEntity repo, int number, IssueState state) =>
      _ds.setIssueState(repo.ownerLogin, repo.name, number,
          state == IssueState.closed ? 'closed' : 'open');

  @override
  Future<List<NotificationEntity>> getNotifications(
      {bool unreadOnly = false}) async {
    final models = await _ds.getNotifications(unreadOnly: unreadOnly);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> markNotificationRead(String id) =>
      _ds.markNotificationRead(id);

  @override
  Future<void> markAllNotificationsRead() => _ds.markAllNotificationsRead();

  @override
  Future<List<ActivityEventEntity>> getActivity({int perPage = 30}) async {
    final models =
        await _ds.getUserEvents(connection.accountLogin, perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GistEntity>> getGists({int perPage = 30}) async {
    final models = await _ds.getGists(perPage: perPage);
    return models.map((m) => m.toEntity()).toList();
  }

  // ─── Inbox ──────────────────────────────────────────────────────────────────
  static const _myPrsQuery = r"""
query {
  search(query: "is:pr is:open archived:false author:@me", type: ISSUE, first: 50) {
    nodes {
      ... on PullRequest {
        number title url updatedAt
        repository { nameWithOwner }
        mergeable
        reviewDecision
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
      }
    }
  }
}""";

  InboxItem _searchItem(Map<String, dynamic> j, InboxReason reason) {
    final isPr = j['pull_request'] != null;
    final repoUrl = j['repository_url'] as String? ?? '';
    final repoFull = repoUrl.split('/repos/').last;
    return InboxItem(
      connectionId: connection.id,
      provider: GitProviderType.github,
      accountLogin: connection.accountLogin,
      kind: isPr ? InboxItemKind.pullRequest : InboxItemKind.issue,
      repoFullName: repoFull,
      number: j['number'] as int,
      title: j['title'] as String? ?? '',
      htmlUrl: j['html_url'] as String? ?? '',
      updatedAt: DateTime.parse(j['updated_at'] as String),
      authorLogin: (j['user'] as Map?)?['login'] as String?,
      reasons: [reason],
    );
  }

  Future<List<InboxItem>> _safe(Future<List<InboxItem>> Function() f) async {
    try {
      return await f();
    } on Exception {
      // One failing query must not blank the whole inbox.
      return const [];
    }
  }

  @override
  Future<List<InboxItem>> getInboxItems() async {
    Future<List<InboxItem>> search(String q, InboxReason r) => _safe(() async =>
        (await _ds.searchIssuesRaw('$q archived:false'))
            .map((j) => _searchItem(j, r))
            .toList());

    final results = await Future.wait([
      search('is:pr is:open review-requested:@me',
          InboxReason.reviewRequested),
      search('is:issue is:open assignee:@me', InboxReason.assigned),
      search('is:pr is:open assignee:@me', InboxReason.assigned),
      search('is:open mentions:@me -author:@me', InboxReason.mentioned),
      _safe(_myPrsNeedingWork),
    ]);
    return InboxItem.mergeAndSort(results.expand((e) => e));
  }

  Future<List<InboxItem>> _myPrsNeedingWork() async {
    final data = await _ds.graphql(_myPrsQuery);
    final nodes = ((data['search'] as Map?)?['nodes'] as List?) ?? const [];
    final out = <InboxItem>[];
    for (final n in nodes.whereType<Map<String, dynamic>>()) {
      if (n['number'] == null) continue;
      final reasons = <InboxReason>[];
      final commits = (n['commits'] as Map?)?['nodes'] as List?;
      final ci = commits == null || commits.isEmpty
          ? null
          : (((commits.first as Map)['commit'] as Map?)?['statusCheckRollup']
              as Map?)?['state'];
      if (ci == 'FAILURE' || ci == 'ERROR') reasons.add(InboxReason.ciFailed);
      if (n['reviewDecision'] == 'CHANGES_REQUESTED') {
        reasons.add(InboxReason.changesRequested);
      }
      if (n['mergeable'] == 'CONFLICTING') reasons.add(InboxReason.conflicts);
      if (reasons.isEmpty) continue;
      out.add(InboxItem(
        connectionId: connection.id,
        provider: GitProviderType.github,
        accountLogin: connection.accountLogin,
        kind: InboxItemKind.pullRequest,
        repoFullName:
            (n['repository'] as Map?)?['nameWithOwner'] as String? ?? '',
        number: n['number'] as int,
        title: n['title'] as String? ?? '',
        htmlUrl: n['url'] as String? ?? '',
        updatedAt: DateTime.parse(n['updatedAt'] as String),
        authorLogin: connection.accountLogin,
        reasons: reasons,
      ));
    }
    return out;
  }
}
