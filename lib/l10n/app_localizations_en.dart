// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get tooltipWorkspaces => 'Workspaces';

  @override
  String get tooltipRepositories => 'Repositories';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnassigned => 'Unassigned';

  @override
  String get filterEverything => 'Everything';

  @override
  String filterWithCount(String label, int count) {
    return '$label · $count';
  }

  @override
  String get emptyTitle => 'You\'re all caught up';

  @override
  String get emptyBody => 'Nothing needs your attention right now.';

  @override
  String bannerCouldntLoad(String account, String reason) {
    return 'Couldn\'t load $account: $reason';
  }

  @override
  String bannerPartial(String account, String reason) {
    return 'Some results from $account may be missing: $reason';
  }

  @override
  String get bannerSavedRefreshing => 'Showing saved results — refreshing…';

  @override
  String get errNetwork => 'Network error or unexpected response.';

  @override
  String get retry => 'Retry';

  @override
  String get swipeDone => 'Done';

  @override
  String get swipeSnooze => 'Snooze';

  @override
  String get snoozeLater => 'Later today (4 hours)';

  @override
  String get snoozeTomorrow => 'Tomorrow';

  @override
  String get snoozeNextWeek => 'Next week';

  @override
  String get markedDone => 'Marked done';

  @override
  String get undo => 'Undo';

  @override
  String get reasonCiFailed => 'CI failed';

  @override
  String get reasonChangesRequested => 'Changes requested';

  @override
  String get reasonConflicts => 'Merge conflicts';

  @override
  String get reasonReviewRequested => 'Review requested';

  @override
  String get reasonAssigned => 'Assigned to you';

  @override
  String get reasonMentioned => 'Mentioned';

  @override
  String get actionRerunCi => 'Re-run failed CI';

  @override
  String get actionApprove => 'Approve';

  @override
  String get actionRequestChanges => 'Request changes';

  @override
  String get actionMerge => 'Merge';

  @override
  String get actionOpenInBrowser => 'Open in browser';

  @override
  String get doneApproved => 'Approved';

  @override
  String get doneChangesRequested => 'Changes requested';

  @override
  String get doneMerged => 'Merged';

  @override
  String get doneCiRerun => 'CI re-run started';

  @override
  String failedWith(String error) {
    return 'Failed: $error';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Send';

  @override
  String get approveTitle => 'Approve?';

  @override
  String approveBody(String ref, String account) {
    return 'Approve $ref as $account?';
  }

  @override
  String get mergeTitle => 'Merge?';

  @override
  String mergeBody(String ref) {
    return 'Merge $ref? This can\'t be undone from here.';
  }

  @override
  String get requestChangesHint => 'What needs to change?';

  @override
  String get detailActions => 'Actions';

  @override
  String get detailMore => 'More';

  @override
  String get detailNoDescription => 'No description.';

  @override
  String detailFilesChanged(int count) {
    return 'Files changed · $count';
  }

  @override
  String detailDiscussion(int count) {
    return 'Discussion · $count';
  }

  @override
  String get detailNoComments => 'No comments yet.';

  @override
  String get detailNoDiff =>
      'No diff available (binary or too large). Open it in the browser.';

  @override
  String detailMoreLines(int count) {
    return '… $count more lines. Open in the browser for the full diff.';
  }

  @override
  String get stateOpen => 'open';

  @override
  String get stateClosed => 'closed';

  @override
  String get stateMerged => 'merged';

  @override
  String get stateDraft => 'draft';

  @override
  String get workspacesTitle => 'Workspaces';

  @override
  String get workspaceNew => 'New workspace';

  @override
  String get workspaceEmptyTitle => 'Group your work by client';

  @override
  String get workspaceEmptyBody =>
      'A workspace combines accounts and orgs from GitHub, GitLab or Azure DevOps under one client name, so your Inbox can show one client at a time.';

  @override
  String get workspaceNoAccounts => 'No accounts yet';

  @override
  String get workspaceRemovedAccount => 'Removed account';

  @override
  String get workspaceNameLabel => 'Client / workspace name';

  @override
  String get workspaceAccountsOrgs => 'Accounts & orgs';

  @override
  String get workspaceOrgHelp =>
      'Leave the org field empty to include the whole account.';

  @override
  String get workspaceAccountLabel => 'Account';

  @override
  String get workspaceOrgLabel => 'Org / group (optional)';

  @override
  String get tooltipRemove => 'Remove';

  @override
  String get workspaceAddRule => 'Add account or org';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get connectAzureUrlLabel =>
      'Organisation URL (https://dev.azure.com/your-org)';

  @override
  String get connectGitlabUrlLabel => 'Self-hosted GitLab URL (optional)';

  @override
  String get connectGiteaUrlLabel =>
      'Forgejo / Gitea URL (e.g. https://codeberg.org)';

  @override
  String get giteaNeedsUrl => 'Forgejo / Gitea needs the server URL.';

  @override
  String get connectGitlabUrlHint => 'Empty = gitlab.com';

  @override
  String get tokenLabel => 'Personal Access Token';

  @override
  String get enterToken => 'Enter a token.';

  @override
  String get azureNeedsOrg => 'Azure DevOps needs an organisation URL.';

  @override
  String get invalidToken => 'Invalid token. Check the value and its scopes.';

  @override
  String get couldNotConnectUrl =>
      'Could not connect. Check the token and the URL.';

  @override
  String get couldNotConnectNet =>
      'Could not connect. Check the token and your internet connection.';

  @override
  String get showToken => 'Show token';

  @override
  String get hideToken => 'Hide token';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connect => 'Connect';

  @override
  String createTokenOn(String provider) {
    return 'Create a token on $provider';
  }

  @override
  String needsScopes(String scopes) {
    return 'Needs: $scopes';
  }

  @override
  String get authTagline => 'One inbox for all your Git work.';

  @override
  String get authSignInGithub => 'Sign in with GitHub';

  @override
  String get authHideOther => 'Hide other options';

  @override
  String get authOtherOptions => 'GitLab, Azure DevOps or a token';

  @override
  String get deviceStep1 => '1. Open this URL in your browser:';

  @override
  String get deviceStep2 => '2. Enter this code:';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get deviceWaiting => 'Waiting for authorisation…';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get connectedAccounts => 'Connected Accounts';

  @override
  String get addAccount => 'Add account';

  @override
  String get connectAccountTitle => 'Connect an account';

  @override
  String get noAccountsConnected =>
      'No accounts connected. Tap \"Add account\" to connect.';

  @override
  String removeProviderTitle(String provider) {
    return 'Remove $provider';
  }

  @override
  String disconnectBody(String account) {
    return 'Disconnect $account? Its repos will be removed from the list.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get alertsTitle => 'Urgent inbox alerts';

  @override
  String get alertsBody =>
      'Failing CI, requested changes, conflicts and review requests. Checked in the background about every 30 minutes; iOS may run it less often.';

  @override
  String get alertsCheckNow => 'Check now';

  @override
  String get alertsPermissionDenied =>
      'Notification permission was denied. Enable it in system settings.';

  @override
  String alertsCouldNotChange(String error) {
    return 'Could not change alerts: $error';
  }

  @override
  String get checkedNothing => 'Checked — nothing new.';

  @override
  String checkedNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new items',
      one: '1 new item',
    );
    return 'Checked — $_temp0.';
  }

  @override
  String checkFailed(String error) {
    return 'Check failed: $error';
  }

  @override
  String get about => 'About';

  @override
  String get aboutApp => 'App';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutProviders => 'Providers';

  @override
  String alertTitleMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need your attention',
      one: '1 item needs your attention',
    );
    return '$_temp0';
  }

  @override
  String alertAndMore(int count) {
    return 'and $count more';
  }

  @override
  String get alertChannelName => 'Inbox alerts';

  @override
  String get alertChannelDescription =>
      'Failing CI, review requests and other urgent items';

  @override
  String get tooltipActivity => 'Activity';

  @override
  String get tooltipGists => 'Gists';

  @override
  String get tooltipExplore => 'Explore GitHub';

  @override
  String get tooltipSort => 'Sort';

  @override
  String get sortUpdated => 'Last updated';

  @override
  String get sortStars => 'Stars';

  @override
  String get sortName => 'Name';

  @override
  String get sortCreated => 'Created';

  @override
  String get tooltipToggleTheme => 'Toggle theme';

  @override
  String get tooltipProfile => 'Profile';

  @override
  String get tooltipLogout => 'Logout';

  @override
  String get disconnectAllTitle => 'Disconnect all';

  @override
  String get disconnectAllBody =>
      'Remove all connected accounts from this device?';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get searchReposHint => 'Search repositories…';

  @override
  String get pinned => 'Pinned';

  @override
  String get noReposFound => 'No repositories found';

  @override
  String get filterOwned => 'Owned';

  @override
  String get filterForked => 'Forked';

  @override
  String get filterStarred => 'Starred';

  @override
  String get filterPublic => 'Public';

  @override
  String get filterPrivate => 'Private';

  @override
  String get shortcutSearch => 'Focus search bar';

  @override
  String get shortcutRefresh => 'Refresh repositories';

  @override
  String get shortcutHelp => 'Show this dialog';

  @override
  String get shortcutsTitle => 'Keyboard Shortcuts';

  @override
  String get close => 'Close';

  @override
  String repoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositories',
      one: '1 repository',
    );
    return '$_temp0';
  }

  @override
  String get unpin => 'Unpin';

  @override
  String get pin => 'Pin';

  @override
  String get browseCode => 'Browse code';

  @override
  String get unstar => 'Unstar';

  @override
  String get star => 'Star';

  @override
  String get copied => 'Copied!';

  @override
  String get copyLink => 'Copy link';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get issues => 'Issues';

  @override
  String get commits => 'Commits';

  @override
  String get releases => 'Releases';

  @override
  String get forkLabel => 'Fork';

  @override
  String get topics => 'Topics';

  @override
  String get recentCommits => 'Recent commits';

  @override
  String get viewAll => 'View all';

  @override
  String get noCommitsFound => 'No commits found';

  @override
  String get forks => 'Forks';

  @override
  String get watchers => 'Watchers';

  @override
  String get languages => 'Languages';

  @override
  String get contributors => 'Contributors';

  @override
  String get clone => 'Clone';

  @override
  String get copy => 'Copy';

  @override
  String openOnProvider(String provider) {
    return 'Open on $provider';
  }

  @override
  String contributorTooltip(String login, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$login · $_temp0';
  }

  @override
  String get noProfileData => 'No profile data';

  @override
  String get reposLabel => 'Repos';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get searchAllHint => 'Search all GitHub repositories…';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchAcrossTitle => 'Search across all of GitHub';

  @override
  String get searchAcrossBody => 'Find repos by name, topic, or description';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get refresh => 'Refresh';

  @override
  String get failedLoadNotifications => 'Failed to load notifications';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get reasonSubscribed => 'Subscribed';

  @override
  String get reasonAssignedShort => 'Assigned';

  @override
  String get reasonAuthor => 'Author';

  @override
  String get reasonCommented => 'Commented';

  @override
  String get reasonTeamMention => 'Team mentioned';

  @override
  String get reasonStateChange => 'State changed';

  @override
  String get failedLoadActivity => 'Failed to load activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get yourGists => 'Your Gists';

  @override
  String get failedLoadGists => 'Failed to load gists';

  @override
  String get noGistsYet => 'No gists yet';

  @override
  String get gistSecret => 'Secret';

  @override
  String get newIssue => 'New issue';

  @override
  String get tabOpen => 'Open';

  @override
  String get tabClosed => 'Closed';

  @override
  String get loadMore => 'Load more';

  @override
  String get tabMerged => 'Merged';

  @override
  String joinedAgo(String time) {
    return 'Joined $time';
  }

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String reposForQuery(int count, String query) {
    return '$count+ repositories for \"$query\"';
  }

  @override
  String updatedAgo(String time) {
    return 'Updated $time';
  }

  @override
  String get noOpenIssues => 'No open issues';

  @override
  String get noClosedIssues => 'No closed issues';

  @override
  String get noOpenPrs => 'No open pull requests';

  @override
  String get noClosedPrs => 'No closed pull requests';

  @override
  String get noMergedPrs => 'No merged pull requests';

  @override
  String openedAgo(String time) {
    return 'opened $time';
  }

  @override
  String closedAgo(String time) {
    return 'closed $time';
  }

  @override
  String byAuthor(String author) {
    return 'by $author';
  }

  @override
  String get prOpen => 'Open';

  @override
  String get prMerged => 'Merged';

  @override
  String get prClosed => 'Closed';

  @override
  String get prDraft => 'Draft';

  @override
  String get noDescriptionProvided => 'No description provided.';

  @override
  String get noCommitsOnBranch => 'No commits on this branch';

  @override
  String get defaultBadge => 'default';

  @override
  String get noReleasesYet => 'No releases yet';

  @override
  String get viewOnGithub => 'View on GitHub';

  @override
  String get copyContent => 'Copy content';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get binaryFile => 'Binary file — cannot display';

  @override
  String get emptyDirectory => 'Empty directory';

  @override
  String get noReadmeFound => 'No README found';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get describeIssueHint => 'Describe the issue… (optional)';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get submitIssue => 'Submit issue';

  @override
  String get comments => 'Comments';

  @override
  String get emptyComment => '(empty comment)';

  @override
  String prTitle(int number) {
    return 'PR #$number';
  }

  @override
  String issueTitle(int number) {
    return 'Issue #$number';
  }

  @override
  String releasedAgo(String time) {
    return 'released $time';
  }

  @override
  String committedAgo(String time) {
    return 'committed $time';
  }

  @override
  String commentedAgo(String time) {
    return 'commented $time';
  }

  @override
  String filesChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String commentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidToken => 'Invalid or expired token. Please reconnect.';

  @override
  String get errForbidden => 'Access forbidden. Check your token scopes.';

  @override
  String get errNotFound => 'Resource not found.';

  @override
  String get errTooMany => 'Too many requests. Try again in a moment.';

  @override
  String get errInvalidRequest =>
      'Invalid request. Check the data and try again.';

  @override
  String get errServer => 'The server is having issues. Try again later.';

  @override
  String errUnexpected(String code) {
    return 'Unexpected error ($code).';
  }

  @override
  String get errCommentRequired => 'A comment is required to request changes.';

  @override
  String get errRateLimited =>
      'GitHub is rate limiting requests. Try again in a minute.';

  @override
  String errRateLimitedIn(String seconds) {
    return 'GitHub is rate limiting requests. Try again in ${seconds}s.';
  }
}
