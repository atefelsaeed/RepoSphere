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
import '../../domain/repositories/git_provider.dart';

/// Base for providers that support the Inbox (list, detail, actions) but not
/// the repository browser yet. Lists come back empty and everything else
/// throws [UnsupportedProviderOperation], so a new provider only needs
/// [getUser], [getInboxItems], [getItemDetail] and [performPrAction].
abstract class InboxOnlyProvider implements GitProvider {
  Never _no(String op) => throw UnsupportedProviderOperation(type, op);

  @override
  Future<List<RepoEntity>> getRepos({int page = 1, int perPage = 100}) async =>
      const [];
  @override
  Future<List<RepoEntity>> getStarredRepos() async => const [];
  @override
  Future<List<RepoEntity>> searchRepos(String query,
          {int page = 1, int perPage = 30}) async =>
      const [];
  @override
  Future<List<BranchEntity>> getBranches(RepoEntity repo) async => const [];
  @override
  Future<List<CommitEntity>> getCommits(RepoEntity repo,
          {String? branch, int page = 1, int perPage = 30}) async =>
      const [];
  @override
  Future<CommitDetailEntity> getCommitDetail(RepoEntity repo, String sha) =>
      _no('commit detail');
  @override
  Future<String?> getReadme(RepoEntity repo) async => null;
  @override
  Future<List<RepoContentItem>> getContents(RepoEntity repo, String path,
          {String? ref}) async =>
      const [];
  @override
  Future<FileContent> getFileContent(RepoEntity repo, String path,
          {String? ref}) =>
      _no('file content');
  @override
  Future<Map<String, int>> getLanguages(RepoEntity repo) async => const {};
  @override
  Future<List<ContributorEntity>> getContributors(RepoEntity repo,
          {int perPage = 8}) async =>
      const [];
  @override
  Future<List<PullRequestEntity>> getPullRequests(RepoEntity repo,
          {String state = 'open', int page = 1, int perPage = 30}) async =>
      const [];
  @override
  Future<List<IssueEntity>> getIssues(RepoEntity repo,
          {String state = 'open', int page = 1, int perPage = 30}) async =>
      const [];
  @override
  Future<List<IssueCommentEntity>> getIssueComments(
          RepoEntity repo, int number) async =>
      const [];
  @override
  Future<List<ReleaseEntity>> getReleases(RepoEntity repo,
          {int perPage = 10}) async =>
      const [];
  @override
  Future<bool> isStarred(RepoEntity repo) async => false;
  @override
  Future<void> setStar(RepoEntity repo, bool starred) => _no('star');
  @override
  Future<IssueEntity> createIssue(RepoEntity repo,
          {required String title, String? body, List<String> labels = const []}) =>
      _no('create issue');
  @override
  Future<IssueCommentEntity> addIssueComment(
          RepoEntity repo, int number, String body) =>
      _no('comment');
  @override
  Future<void> mergePullRequest(RepoEntity repo, int number) =>
      _no('merge pull request');
  @override
  Future<void> setIssueState(RepoEntity repo, int number, IssueState state) =>
      _no('issue state');
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
