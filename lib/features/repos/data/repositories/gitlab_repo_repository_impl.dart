import 'dart:convert';
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
import '../datasources/gitlab_remote_datasource.dart';

/// GitLab adapter — maps the v4 REST API to the shared domain entities.
/// Read-complete for this phase; mutating operations throw
/// [UnsupportedProviderOperation] except notification acknowledgement.
class GitLabRepoRepositoryImpl implements GitProvider {
  final GitLabRemoteDatasource _ds;
  @override
  final GitConnection connection;

  const GitLabRepoRepositoryImpl(this._ds, this.connection);

  @override
  GitProviderType get type => GitProviderType.gitlab;

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        pullRequests: true,
        issues: true,
        releases: true,
        notifications: true,
        activity: true,
        fileTree: true,
        contributors: true,
        languages: true,
        search: true,
      );

  // ─── Helpers ────────────────────────────────────────────────────────────────
  RepoEntity _stamp(RepoEntity r) =>
      r.copyWith(provider: GitProviderType.gitlab, connectionId: connection.id);

  static DateTime _date(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime? _dateOrNull(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  /// Maps GitHub-style state to GitLab issue/MR state.
  static String _issueState(String s) => switch (s) {
        'open' => 'opened',
        'closed' => 'closed',
        _ => 'all',
      };

  static List<LabelEntity> _labels(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((l) => LabelEntity(name: l.toString(), color: '8E8E93'))
        .toList();
  }

  // ─── Account ────────────────────────────────────────────────────────────────
  @override
  Future<UserEntity> getUser() async {
    final j = await _ds.getUserJson();
    return UserEntity(
      login: j['username'] as String? ?? '',
      name: j['name'] as String?,
      avatarUrl: j['avatar_url'] as String? ?? '',
      bio: j['bio'] as String?,
      location: j['location'] as String?,
      company: j['organization'] as String?,
      email: j['public_email'] as String?,
      blog: j['web_url'] as String?,
      publicRepos: 0,
      followers: 0,
      following: 0,
      createdAt: _dateOrNull(j['created_at']),
    );
  }

  // ─── Repositories ────────────────────────────────────────────────────────────
  @override
  Future<List<RepoEntity>> getRepos({int page = 1, int perPage = 100}) async {
    final models = await _ds.getProjects(perPage: perPage);
    return models.map((m) => _stamp(m.toEntity())).toList();
  }

  @override
  Future<List<RepoEntity>> getStarredRepos() async {
    final models = await _ds.getStarredProjects();
    return models.map((m) => _stamp(m.toEntity())).toList();
  }

  @override
  Future<List<RepoEntity>> searchRepos(String query,
      {int page = 1, int perPage = 30}) async {
    final models = await _ds.searchProjects(query, perPage: perPage);
    return models.map((m) => _stamp(m.toEntity())).toList();
  }

  // ─── Code ────────────────────────────────────────────────────────────────────
  @override
  Future<List<BranchEntity>> getBranches(RepoEntity repo) async {
    final list = await _ds.getBranches(repo.id);
    return list.map((b) {
      final m = b as Map<String, dynamic>;
      return BranchEntity(
        name: m['name'] as String? ?? '',
        sha: (m['commit'] as Map?)?['id'] as String? ?? '',
        isProtected: m['protected'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<List<CommitEntity>> getCommits(RepoEntity repo,
      {String? branch, int page = 1, int perPage = 30}) async {
    final list = await _ds.getCommits(repo.id,
        branch: branch, page: page, perPage: perPage);
    return list.map((c) {
      final m = c as Map<String, dynamic>;
      return CommitEntity(
        sha: m['id'] as String? ?? '',
        message: m['message'] as String? ?? '',
        authorName: m['author_name'] as String? ?? '',
        date: _date(m['created_at']),
        htmlUrl: m['web_url'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<CommitDetailEntity> getCommitDetail(RepoEntity repo, String sha) async {
    final m = await _ds.getCommit(repo.id, sha);
    final diff = await _ds.getCommitDiff(repo.id, sha);
    final stats = m['stats'] as Map<String, dynamic>? ?? const {};
    final files = diff.map((d) {
      final f = d as Map<String, dynamic>;
      final status = (f['new_file'] == true)
          ? 'added'
          : (f['deleted_file'] == true)
              ? 'removed'
              : (f['renamed_file'] == true)
                  ? 'renamed'
                  : 'modified';
      return CommitFileChange(
        filename: f['new_path'] as String? ?? f['old_path'] as String? ?? '',
        status: status,
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: f['diff'] as String?,
      );
    }).toList();
    return CommitDetailEntity(
      sha: m['id'] as String? ?? sha,
      message: m['message'] as String? ?? '',
      authorName: m['author_name'] as String? ?? '',
      date: _date(m['created_at']),
      htmlUrl: m['web_url'] as String? ?? '',
      totalAdditions: stats['additions'] as int? ?? 0,
      totalDeletions: stats['deletions'] as int? ?? 0,
      files: files,
    );
  }

  @override
  Future<String?> getReadme(RepoEntity repo) async {
    for (final name in const ['README.md', 'README.rst', 'README']) {
      try {
        final m =
            await _ds.getFile(repo.id, name, ref: repo.defaultBranch);
        return _decodeContent(m);
      } catch (_) {
        // try next candidate
      }
    }
    return null;
  }

  @override
  Future<List<RepoContentItem>> getContents(RepoEntity repo, String path,
      {String? ref}) async {
    final list = await _ds.getTree(repo.id, path, ref: ref ?? repo.defaultBranch);
    final items = list.map((e) {
      final m = e as Map<String, dynamic>;
      final isTree = m['type'] == 'tree';
      return RepoContentItem(
        name: m['name'] as String? ?? '',
        path: m['path'] as String? ?? '',
        type: isTree ? ContentType.dir : ContentType.file,
        size: null,
        downloadUrl: null,
        sha: m['id'] as String? ?? '',
      );
    }).toList()
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
    final m = await _ds.getFile(repo.id, path, ref: ref ?? repo.defaultBranch);
    return FileContent(
      path: m['file_path'] as String? ?? path,
      content: _decodeContent(m),
      encoding: 'utf-8',
    );
  }

  static String _decodeContent(Map<String, dynamic> m) {
    final raw = (m['content'] as String? ?? '').replaceAll('\n', '');
    if ((m['encoding'] as String?) == 'base64') {
      return utf8.decode(base64.decode(raw));
    }
    return raw;
  }

  @override
  Future<Map<String, int>> getLanguages(RepoEntity repo) async {
    final m = await _ds.getLanguages(repo.id);
    return m.map((k, v) => MapEntry(k, ((v as num) * 100).round()));
  }

  @override
  Future<List<ContributorEntity>> getContributors(RepoEntity repo,
      {int perPage = 8}) async {
    final list = await _ds.getContributors(repo.id);
    return list.map((c) {
      final m = c as Map<String, dynamic>;
      return ContributorEntity(
        login: m['name'] as String? ?? '',
        avatarUrl: '',
        htmlUrl: '',
        contributions: m['commits'] as int? ?? 0,
      );
    }).toList();
  }

  // ─── Collaboration ───────────────────────────────────────────────────────────
  @override
  Future<List<PullRequestEntity>> getPullRequests(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30}) async {
    final list = await _ds.getMergeRequests(repo.id,
        state: _issueState(state), page: page, perPage: perPage);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final author = m['author'] as Map<String, dynamic>? ?? const {};
      final glState = m['state'] as String? ?? 'opened';
      return PullRequestEntity(
        number: m['iid'] as int? ?? 0,
        title: m['title'] as String? ?? '',
        state: switch (glState) {
          'merged' => PrState.merged,
          'closed' => PrState.closed,
          _ => PrState.open,
        },
        body: m['description'] as String?,
        htmlUrl: m['web_url'] as String? ?? '',
        authorLogin: author['username'] as String? ?? '',
        authorAvatarUrl: author['avatar_url'] as String?,
        headBranch: m['source_branch'] as String? ?? '',
        baseBranch: m['target_branch'] as String? ?? '',
        labels: _labels(m['labels']),
        commentsCount: m['user_notes_count'] as int? ?? 0,
        createdAt: _date(m['created_at']),
        updatedAt: _date(m['updated_at']),
        mergedAt: _dateOrNull(m['merged_at']),
        closedAt: _dateOrNull(m['closed_at']),
      );
    }).toList();
  }

  @override
  Future<List<IssueEntity>> getIssues(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30}) async {
    final list = await _ds.getIssues(repo.id,
        state: _issueState(state), page: page, perPage: perPage);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final author = m['author'] as Map<String, dynamic>? ?? const {};
      return IssueEntity(
        number: m['iid'] as int? ?? 0,
        title: m['title'] as String? ?? '',
        state: (m['state'] == 'closed') ? IssueState.closed : IssueState.open,
        body: m['description'] as String?,
        htmlUrl: m['web_url'] as String? ?? '',
        authorLogin: author['username'] as String? ?? '',
        authorAvatarUrl: author['avatar_url'] as String?,
        labels: _labels(m['labels']),
        commentsCount: m['user_notes_count'] as int? ?? 0,
        createdAt: _date(m['created_at']),
        updatedAt: _date(m['updated_at']),
        closedAt: _dateOrNull(m['closed_at']),
      );
    }).toList();
  }

  @override
  Future<List<IssueCommentEntity>> getIssueComments(
      RepoEntity repo, int number) async {
    final list = await _ds.getIssueNotes(repo.id, number);
    return list
        .where((n) => (n as Map)['system'] != true)
        .map((e) {
          final m = e as Map<String, dynamic>;
          final author = m['author'] as Map<String, dynamic>? ?? const {};
          return IssueCommentEntity(
            id: m['id'] as int? ?? 0,
            authorLogin: author['username'] as String? ?? '',
            authorAvatarUrl: author['avatar_url'] as String?,
            body: m['body'] as String? ?? '',
            createdAt: _date(m['created_at']),
            htmlUrl: '',
          );
        })
        .toList();
  }

  @override
  Future<List<ReleaseEntity>> getReleases(RepoEntity repo,
      {int perPage = 10}) async {
    final list = await _ds.getReleases(repo.id);
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final author = m['author'] as Map<String, dynamic>? ?? const {};
      final links = m['_links'] as Map<String, dynamic>? ?? const {};
      final tag = m['tag_name'] as String? ?? '';
      return ReleaseEntity(
        id: tag.hashCode,
        tagName: tag,
        name: m['name'] as String?,
        body: m['description'] as String?,
        publishedAt: _date(m['released_at'] ?? m['created_at']),
        isDraft: false,
        isPreRelease: m['upcoming_release'] as bool? ?? false,
        htmlUrl: links['self'] as String? ?? '',
        authorLogin: author['username'] as String? ?? '',
        authorAvatarUrl: author['avatar_url'] as String?,
      );
    }).toList();
  }

  // ─── Writes ──────────────────────────────────────────────────────────────────
  @override
  Future<bool> isStarred(RepoEntity repo) async => false;

  @override
  Future<void> setStar(RepoEntity repo, bool starred) async =>
      throw const UnsupportedProviderOperation(GitProviderType.gitlab, 'star');

  @override
  Future<IssueEntity> createIssue(RepoEntity repo,
          {required String title,
          String? body,
          List<String> labels = const []}) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.gitlab, 'createIssue');

  @override
  Future<IssueCommentEntity> addIssueComment(
          RepoEntity repo, int number, String body) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.gitlab, 'addIssueComment');

  @override
  Future<void> mergePullRequest(RepoEntity repo, int number) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.gitlab, 'mergePullRequest');

  @override
  Future<void> setIssueState(
          RepoEntity repo, int number, IssueState state) async =>
      throw const UnsupportedProviderOperation(
          GitProviderType.gitlab, 'setIssueState');

  // ─── Account feeds ───────────────────────────────────────────────────────────
  @override
  Future<List<NotificationEntity>> getNotifications(
      {bool unreadOnly = false}) async {
    final list = await _ds.getTodos();
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final project = m['project'] as Map<String, dynamic>? ?? const {};
      final target = m['target'] as Map<String, dynamic>? ?? const {};
      return NotificationEntity(
        id: '${m['id']}',
        title: target['title'] as String? ?? m['body'] as String? ?? '',
        subjectType: m['target_type'] as String? ?? '',
        repoFullName: project['path_with_namespace'] as String? ?? '',
        reason: m['action_name'] as String? ?? '',
        unread: m['state'] == 'pending',
        updatedAt: _date(m['updated_at'] ?? m['created_at']),
        htmlUrl: m['target_url'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<void> markNotificationRead(String id) => _ds.markTodoDone(id);

  @override
  Future<void> markAllNotificationsRead() => _ds.markAllTodosDone();

  @override
  Future<List<ActivityEventEntity>> getActivity({int perPage = 30}) async {
    final list = await _ds.getEvents();
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final action = m['action_name'] as String? ?? '';
      final targetType = m['target_type'] as String? ?? '';
      final targetTitle = m['target_title'] as String? ?? '';
      return ActivityEventEntity(
        id: '${m['id']}',
        type: action,
        actorLogin: m['author_username'] as String? ??
            (m['author'] as Map?)?['username'] as String? ??
            '',
        actorAvatarUrl: (m['author'] as Map?)?['avatar_url'] as String?,
        repoName: '',
        createdAt: _date(m['created_at']),
        summary: '$action $targetType $targetTitle'.trim(),
      );
    }).toList();
  }

  @override
  Future<List<GistEntity>> getGists({int perPage = 30}) async =>
      throw const UnsupportedProviderOperation(GitProviderType.gitlab, 'gists');
}
