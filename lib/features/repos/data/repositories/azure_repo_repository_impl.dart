import '../../../../core/git/git_provider_type.dart';
import '../../../auth/domain/git_connection.dart';
import '../../domain/entities/activity_event_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/commit_detail_entity.dart';
import '../../domain/entities/commit_entity.dart';
import '../../domain/entities/contributor_entity.dart';
import '../../domain/entities/gist_entity.dart';
import '../../domain/entities/issue_comment_entity.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/pull_request_entity.dart';
import '../../domain/entities/release_entity.dart';
import '../../domain/entities/repo_content_entity.dart';
import '../../domain/entities/repo_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/git_provider.dart';
import '../datasources/azure_remote_datasource.dart';

/// Azure DevOps adapter (proof-of-concept). Repositories live under an
/// organisation → project → repo hierarchy; "issues" are surfaced as Work
/// Items via WIQL. Read-only for this phase; unsupported reads return empties
/// and mutations throw [UnsupportedProviderOperation].
class AzureRepoRepositoryImpl implements GitProvider {
  final AzureRemoteDatasource _ds;
  @override
  final GitConnection connection;

  const AzureRepoRepositoryImpl(this._ds, this.connection);

  @override
  GitProviderType get type => GitProviderType.azureDevOps;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        pullRequests: true,
        workItems: true,
        fileTree: true,
      );

  static String _stripRef(String? ref) =>
      (ref ?? '').replaceFirst('refs/heads/', '');

  static DateTime _date(dynamic v) =>
      v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();

  static DateTime? _dateOrNull(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  // ─── Account ────────────────────────────────────────────────────────────────
  @override
  Future<UserEntity> getUser() async {
    final data = await _ds.getConnectionData();
    final u = data['authenticatedUser'] as Map<String, dynamic>? ?? const {};
    final login = u['providerDisplayName'] as String? ??
        u['customDisplayName'] as String? ??
        connection.accountLogin;
    return UserEntity(
      login: login,
      name: u['customDisplayName'] as String?,
      avatarUrl: '',
      publicRepos: 0,
      followers: 0,
      following: 0,
    );
  }

  // ─── Repositories ────────────────────────────────────────────────────────────
  @override
  Future<List<RepoEntity>> getRepos({int page = 1, int perPage = 100}) async {
    final list = await _ds.getRepositories();
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final project =
          (m['project'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      final name = m['name'] as String? ?? '';
      final guid = m['id'] as String? ?? '';
      return RepoEntity(
        id: guid.hashCode,
        name: name,
        fullName: '$project/$name',
        description: null,
        htmlUrl: m['webUrl'] as String? ?? m['remoteUrl'] as String? ?? '',
        language: null,
        stargazersCount: 0,
        forksCount: 0,
        watchersCount: 0,
        openIssuesCount: 0,
        isPrivate: true,
        isFork: m['isFork'] as bool? ?? false,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        ownerLogin: project,
        ownerAvatarUrl: '',
        topics: const [],
        defaultBranch: _stripRef(m['defaultBranch'] as String?),
        provider: GitProviderType.azureDevOps,
        connectionId: connection.id,
        providerId: guid,
      );
    }).toList();
  }

  @override
  Future<List<RepoEntity>> getStarredRepos() async => const [];

  @override
  Future<List<RepoEntity>> searchRepos(String query,
      {int page = 1, int perPage = 30}) async {
    final all = await getRepos();
    final q = query.toLowerCase();
    return all.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  // ─── Code ────────────────────────────────────────────────────────────────────
  @override
  Future<List<BranchEntity>> getBranches(RepoEntity repo) async {
    final list = await _ds.getBranches(repo.providerId);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return BranchEntity(
        name: _stripRef(m['name'] as String?),
        sha: m['objectId'] as String? ?? '',
        isProtected: false,
      );
    }).toList();
  }

  @override
  Future<List<CommitEntity>> getCommits(RepoEntity repo,
      {String? branch, int page = 1, int perPage = 30}) async {
    final list = await _ds.getCommits(repo.providerId,
        branch: branch ?? repo.defaultBranch, top: perPage);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final author = m['author'] as Map<String, dynamic>? ?? const {};
      return CommitEntity(
        sha: m['commitId'] as String? ?? '',
        message: m['comment'] as String? ?? '',
        authorName: author['name'] as String? ?? '',
        date: _date(author['date']),
        htmlUrl: m['remoteUrl'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<CommitDetailEntity> getCommitDetail(RepoEntity repo, String sha) async {
    final m = await _ds.getCommit(repo.providerId, sha);
    final changes = await _ds.getCommitChanges(repo.providerId, sha);
    final author = m['author'] as Map<String, dynamic>? ?? const {};
    final files = changes
        .where((c) => (c as Map)['item'] != null)
        .map((c) {
          final f = c as Map<String, dynamic>;
          final item = f['item'] as Map<String, dynamic>;
          if (item['isFolder'] == true) return null;
          final ct = (f['changeType'] as String? ?? '').toLowerCase();
          final status = ct.contains('add')
              ? 'added'
              : ct.contains('delete')
                  ? 'removed'
                  : ct.contains('rename')
                      ? 'renamed'
                      : 'modified';
          return CommitFileChange(
            filename: item['path'] as String? ?? '',
            status: status,
            additions: 0,
            deletions: 0,
            changes: 0,
          );
        })
        .whereType<CommitFileChange>()
        .toList();
    return CommitDetailEntity(
      sha: m['commitId'] as String? ?? sha,
      message: m['comment'] as String? ?? '',
      authorName: author['name'] as String? ?? '',
      date: _date(author['date']),
      htmlUrl: m['remoteUrl'] as String? ?? '',
      totalAdditions: 0,
      totalDeletions: 0,
      files: files,
    );
  }

  @override
  Future<String?> getReadme(RepoEntity repo) async {
    for (final name in const ['README.md', 'readme.md', 'README']) {
      try {
        return await _ds.getFileContent(repo.providerId, '/$name',
            branch: repo.defaultBranch);
      } catch (_) {
        // try next
      }
    }
    return null;
  }

  @override
  Future<List<RepoContentItem>> getContents(RepoEntity repo, String path,
      {String? ref}) async {
    final scope = path.isEmpty ? '/' : (path.startsWith('/') ? path : '/$path');
    final list = await _ds.getItems(repo.providerId, scope,
        branch: ref ?? repo.defaultBranch);
    final items = list
        .where((e) => (e as Map)['path'] != scope)
        .map((e) {
          final m = e as Map<String, dynamic>;
          final p = (m['path'] as String? ?? '').replaceFirst('/', '');
          final isFolder = m['isFolder'] as bool? ??
              (m['gitObjectType'] == 'tree');
          return RepoContentItem(
            name: p.split('/').last,
            path: p,
            type: isFolder ? ContentType.dir : ContentType.file,
            size: null,
            downloadUrl: null,
            sha: m['objectId'] as String? ?? '',
          );
        })
        .toList()
      ..sort((a, b) {
        if (a.isDir && !b.isDir) return -1;
        if (!a.isDir && b.isDir) return 1;
        return a.name.compareTo(b.name);
      });
    return items;
  }

  @override
  Future<FileContent> getFileContent(RepoEntity repo, String path,
      {String? ref}) async {
    final p = path.startsWith('/') ? path : '/$path';
    final content =
        await _ds.getFileContent(repo.providerId, p, branch: ref ?? repo.defaultBranch);
    return FileContent(path: path, content: content, encoding: 'utf-8');
  }

  @override
  Future<Map<String, int>> getLanguages(RepoEntity repo) async => const {};

  @override
  Future<List<ContributorEntity>> getContributors(RepoEntity repo,
          {int perPage = 8}) async =>
      const [];

  // ─── Pull requests ────────────────────────────────────────────────────────────
  @override
  Future<List<PullRequestEntity>> getPullRequests(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30}) async {
    final status = switch (state) {
      'open' => 'active',
      'closed' => 'completed',
      _ => 'all',
    };
    final list =
        await _ds.getPullRequests(repo.providerId, status: status, top: perPage);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final by = m['createdBy'] as Map<String, dynamic>? ?? const {};
      final azStatus = m['status'] as String? ?? 'active';
      return PullRequestEntity(
        number: m['pullRequestId'] as int? ?? 0,
        title: m['title'] as String? ?? '',
        state: switch (azStatus) {
          'completed' => PrState.merged,
          'abandoned' => PrState.closed,
          _ => PrState.open,
        },
        body: m['description'] as String?,
        htmlUrl: '${connection.baseUrl ?? ''}/_git/${repo.name}/pullrequest/${m['pullRequestId']}',
        authorLogin: by['displayName'] as String? ?? '',
        authorAvatarUrl: by['imageUrl'] as String?,
        headBranch: _stripRef(m['sourceRefName'] as String?),
        baseBranch: _stripRef(m['targetRefName'] as String?),
        labels: const [],
        commentsCount: 0,
        createdAt: _date(m['creationDate']),
        updatedAt: _date(m['creationDate']),
        mergedAt: azStatus == 'completed' ? _dateOrNull(m['closedDate']) : null,
        closedAt: _dateOrNull(m['closedDate']),
      );
    }).toList();
  }

  // ─── Work items (issue tracker slot) ───────────────────────────────────────────
  @override
  Future<List<IssueEntity>> getIssues(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30}) async {
    final project = repo.ownerLogin;
    final stateClause = switch (state) {
      'open' =>
        " AND [System.State] NOT IN ('Closed','Done','Removed','Resolved')",
      'closed' => " AND [System.State] IN ('Closed','Done','Removed','Resolved')",
      _ => '',
    };
    final wiql =
        "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '$project'$stateClause ORDER BY [System.ChangedDate] DESC";
    final refs = await _ds.queryWorkItems(project, wiql);
    final ids = refs
        .map((r) => (r as Map<String, dynamic>)['id'] as int?)
        .whereType<int>()
        .take(perPage)
        .toList();
    final items = await _ds.getWorkItems(ids);
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      final f = m['fields'] as Map<String, dynamic>? ?? const {};
      final stateStr = f['System.State'] as String? ?? '';
      final createdBy = f['System.CreatedBy'];
      final author = createdBy is Map<String, dynamic>
          ? (createdBy['displayName'] as String? ?? '')
          : (createdBy?.toString() ?? '');
      final id = m['id'] as int? ?? 0;
      final type = f['System.WorkItemType'] as String? ?? 'Work Item';
      final closed = const ['Closed', 'Done', 'Removed', 'Resolved']
          .contains(stateStr);
      return IssueEntity(
        number: id,
        title: f['System.Title'] as String? ?? '',
        state: closed ? IssueState.closed : IssueState.open,
        body: f['System.Description'] as String?,
        htmlUrl:
            '${connection.baseUrl ?? ''}/${Uri.encodeComponent(project)}/_workitems/edit/$id',
        authorLogin: author,
        authorAvatarUrl: null,
        labels: [LabelEntity(name: type, color: '5765F2')],
        commentsCount: 0,
        createdAt: _date(f['System.CreatedDate']),
        updatedAt: _date(f['System.ChangedDate']),
        closedAt: null,
      );
    }).toList();
  }

  @override
  Future<List<IssueCommentEntity>> getIssueComments(
          RepoEntity repo, int number) async =>
      const [];

  @override
  Future<List<ReleaseEntity>> getReleases(RepoEntity repo,
          {int perPage = 10}) async =>
      const [];

  // ─── Writes ──────────────────────────────────────────────────────────────────
  @override
  Future<bool> isStarred(RepoEntity repo) async => false;

  @override
  Future<void> setStar(RepoEntity repo, bool starred) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.azureDevOps, 'star');

  @override
  Future<IssueEntity> createIssue(RepoEntity repo,
          {required String title,
          String? body,
          List<String> labels = const []}) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.azureDevOps, 'createIssue');

  @override
  Future<IssueCommentEntity> addIssueComment(
          RepoEntity repo, int number, String body) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.azureDevOps, 'addIssueComment');

  @override
  Future<void> mergePullRequest(RepoEntity repo, int number) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.azureDevOps, 'mergePullRequest');

  @override
  Future<void> setIssueState(
          RepoEntity repo, int number, IssueState state) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.azureDevOps, 'setIssueState');

  // ─── Account feeds (unsupported → empty) ───────────────────────────────────────
  @override
  Future<List<NotificationEntity>> getNotifications(
          {bool unreadOnly = false}) async =>
      const [];

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<void> markAllNotificationsRead() async {}

  @override
  Future<List<ActivityEventEntity>> getActivity({int perPage = 30}) async =>
      const [];

  @override
  Future<List<GistEntity>> getGists({int perPage = 30}) async => const [];
}
