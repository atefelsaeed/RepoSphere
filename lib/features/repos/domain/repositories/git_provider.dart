import '../../../../core/git/git_provider_type.dart';
import '../../../auth/domain/git_connection.dart';
import '../entities/activity_event_entity.dart';
import '../entities/branch_entity.dart';
import '../entities/commit_detail_entity.dart';
import '../entities/commit_entity.dart';
import '../entities/contributor_entity.dart';
import '../entities/gist_entity.dart';
import '../entities/inbox_item_entity.dart';
import '../entities/issue_comment_entity.dart';
import '../entities/issue_entity.dart';
import '../entities/item_detail_entity.dart';
import '../entities/notification_entity.dart';
import '../entities/pull_request_entity.dart';
import '../entities/release_entity.dart';
import '../entities/repo_content_entity.dart';
import '../entities/repo_entity.dart';
import '../entities/user_entity.dart';

enum RepoFilter { all, owned, forked, starred, publicOnly, privateOnly }

/// Thrown when a provider does not support a requested operation
/// (e.g. asking Azure DevOps for GitHub-style gists). Call sites should gate
/// on [ProviderCapabilities] instead of catching this where possible.
class UnsupportedProviderOperation implements Exception {
  final GitProviderType provider;
  final String operation;
  const UnsupportedProviderOperation(this.provider, this.operation);

  @override
  String toString() =>
      '${provider.label} does not support "$operation".';
}

/// Declares which features a concrete provider supports so the UI can hide or
/// disable controls (tabs, FABs, menu items) per connection.
class ProviderCapabilities {
  final bool pullRequests;
  final bool issues; // GitHub/GitLab/Gitea issues
  final bool workItems; // Azure DevOps work items (shown in the issues slot)
  final bool releases;
  final bool gists;
  final bool notifications;
  final bool activity;
  final bool starring;
  final bool fileTree;
  final bool contributors;
  final bool languages;
  final bool search;
  final bool writeComments;
  final bool mergePullRequests;
  final bool editIssueState;
  final bool createIssues;

  /// Can answer "what needs my attention?" via [GitProvider.getInboxItems].
  final bool inbox;

  /// Can show an inbox item's description, diff and comments in-app.
  final bool itemDetail;

  /// Inbox quick actions on a PR/MR (merge uses [mergePullRequests]).
  final bool approvePullRequests;
  final bool requestChanges;
  final bool rerunCi;

  const ProviderCapabilities({
    this.pullRequests = false,
    this.issues = false,
    this.workItems = false,
    this.releases = false,
    this.gists = false,
    this.notifications = false,
    this.activity = false,
    this.starring = false,
    this.fileTree = false,
    this.contributors = false,
    this.languages = false,
    this.search = false,
    this.writeComments = false,
    this.mergePullRequests = false,
    this.editIssueState = false,
    this.createIssues = false,
    this.inbox = false,
    this.itemDetail = false,
    this.approvePullRequests = false,
    this.requestChanges = false,
    this.rerunCi = false,
  });

  /// Whether an issue-like tab should be shown (issues OR work items).
  bool get hasIssueTracker => issues || workItems;
}

/// Provider-neutral gateway to a single connected Git account.
///
/// Concrete adapters (GitHub, GitLab, Azure DevOps, …) translate these calls to
/// their REST APIs and map responses to the shared domain entities. Operations
/// that a provider cannot perform throw [UnsupportedProviderOperation]; callers
/// should consult [capabilities] first.
abstract class GitProvider {
  GitProviderType get type;
  GitConnection get connection;
  ProviderCapabilities get capabilities;

  // ─── Account ──────────────────────────────────────────────────────────────
  Future<UserEntity> getUser();

  // ─── Repositories ───────────────────────────────────────────────────────────
  Future<List<RepoEntity>> getRepos({int page = 1, int perPage = 100});
  Future<List<RepoEntity>> getStarredRepos();
  Future<List<RepoEntity>> searchRepos(String query,
      {int page = 1, int perPage = 30});

  // ─── Code ───────────────────────────────────────────────────────────────────
  Future<List<BranchEntity>> getBranches(RepoEntity repo);
  Future<List<CommitEntity>> getCommits(RepoEntity repo,
      {String? branch, int page = 1, int perPage = 30});
  Future<CommitDetailEntity> getCommitDetail(RepoEntity repo, String sha);
  Future<String?> getReadme(RepoEntity repo);
  Future<List<RepoContentItem>> getContents(RepoEntity repo, String path,
      {String? ref});
  Future<FileContent> getFileContent(RepoEntity repo, String path,
      {String? ref});
  Future<Map<String, int>> getLanguages(RepoEntity repo);
  Future<List<ContributorEntity>> getContributors(RepoEntity repo,
      {int perPage = 8});

  // ─── Collaboration ──────────────────────────────────────────────────────────
  /// [state] uses GitHub-style values: `open`, `closed`, `all`.
  Future<List<PullRequestEntity>> getPullRequests(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30});
  Future<List<IssueEntity>> getIssues(RepoEntity repo,
      {String state = 'open', int page = 1, int perPage = 30});
  Future<List<IssueCommentEntity>> getIssueComments(
      RepoEntity repo, int number);
  Future<List<ReleaseEntity>> getReleases(RepoEntity repo, {int perPage = 10});

  // ─── Writes (guard with capabilities) ───────────────────────────────────────
  Future<bool> isStarred(RepoEntity repo);
  Future<void> setStar(RepoEntity repo, bool starred);
  Future<IssueEntity> createIssue(RepoEntity repo,
      {required String title, String? body, List<String> labels});
  Future<IssueCommentEntity> addIssueComment(
      RepoEntity repo, int number, String body);
  Future<void> mergePullRequest(RepoEntity repo, int number);
  Future<void> setIssueState(RepoEntity repo, int number, IssueState state);

  // ─── Account-level feeds ────────────────────────────────────────────────────
  Future<List<NotificationEntity>> getNotifications({bool unreadOnly = false});
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<List<ActivityEventEntity>> getActivity({int perPage = 30});
  Future<List<GistEntity>> getGists({int perPage = 30});

  /// Open PRs/issues across all repos of this account that need the user's
  /// attention (review requests, failing CI, assignments, mentions).
  Future<InboxBatch> getInboxItems();

  /// Description, changed files (PRs/MRs only) and comments for an inbox
  /// [item]. Throws [UnsupportedProviderOperation] when not available.
  Future<ItemDetail> getItemDetail(InboxItem item);

  /// Runs a one-tap [action] on an inbox PR/MR. [comment] is the review body
  /// (required by GitHub for [PrAction.requestChanges]). Throws
  /// [UnsupportedProviderOperation] when the provider can't do it.
  Future<void> performPrAction(InboxItem item, PrAction action,
      {String? comment});
}
