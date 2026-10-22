import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @tooltipWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get tooltipWorkspaces;

  /// No description provided for @tooltipRepositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get tooltipRepositories;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get filterUnassigned;

  /// No description provided for @filterEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get filterEverything;

  /// No description provided for @filterWithCount.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}'**
  String filterWithCount(String label, int count);

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your attention right now.'**
  String get emptyBody;

  /// No description provided for @bannerCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {account}: {reason}'**
  String bannerCouldntLoad(String account, String reason);

  /// No description provided for @bannerPartial.
  ///
  /// In en, this message translates to:
  /// **'Some results from {account} may be missing: {reason}'**
  String bannerPartial(String account, String reason);

  /// No description provided for @bannerSavedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Showing saved results — refreshing…'**
  String get bannerSavedRefreshing;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error or unexpected response.'**
  String get errNetwork;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @swipeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get swipeDone;

  /// No description provided for @swipeSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get swipeSnooze;

  /// No description provided for @snoozeLater.
  ///
  /// In en, this message translates to:
  /// **'Later today (4 hours)'**
  String get snoozeLater;

  /// No description provided for @snoozeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get snoozeTomorrow;

  /// No description provided for @snoozeNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get snoozeNextWeek;

  /// No description provided for @markedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked done'**
  String get markedDone;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @reasonCiFailed.
  ///
  /// In en, this message translates to:
  /// **'CI failed'**
  String get reasonCiFailed;

  /// No description provided for @reasonChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get reasonChangesRequested;

  /// No description provided for @reasonConflicts.
  ///
  /// In en, this message translates to:
  /// **'Merge conflicts'**
  String get reasonConflicts;

  /// No description provided for @reasonReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get reasonReviewRequested;

  /// No description provided for @reasonAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get reasonAssigned;

  /// No description provided for @reasonMentioned.
  ///
  /// In en, this message translates to:
  /// **'Mentioned'**
  String get reasonMentioned;

  /// No description provided for @actionRerunCi.
  ///
  /// In en, this message translates to:
  /// **'Re-run failed CI'**
  String get actionRerunCi;

  /// No description provided for @actionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get actionApprove;

  /// No description provided for @actionRequestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request changes'**
  String get actionRequestChanges;

  /// No description provided for @actionMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get actionMerge;

  /// No description provided for @actionOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get actionOpenInBrowser;

  /// No description provided for @doneApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get doneApproved;

  /// No description provided for @doneChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get doneChangesRequested;

  /// No description provided for @doneMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get doneMerged;

  /// No description provided for @doneCiRerun.
  ///
  /// In en, this message translates to:
  /// **'CI re-run started'**
  String get doneCiRerun;

  /// No description provided for @failedWith.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWith(String error);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @approveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve?'**
  String get approveTitle;

  /// No description provided for @approveBody.
  ///
  /// In en, this message translates to:
  /// **'Approve {ref} as {account}?'**
  String approveBody(String ref, String account);

  /// No description provided for @mergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge?'**
  String get mergeTitle;

  /// No description provided for @mergeBody.
  ///
  /// In en, this message translates to:
  /// **'Merge {ref}? This can\'t be undone from here.'**
  String mergeBody(String ref);

  /// No description provided for @requestChangesHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to change?'**
  String get requestChangesHint;

  /// No description provided for @detailActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get detailActions;

  /// No description provided for @detailMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get detailMore;

  /// No description provided for @detailNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description.'**
  String get detailNoDescription;

  /// No description provided for @detailFilesChanged.
  ///
  /// In en, this message translates to:
  /// **'Files changed · {count}'**
  String detailFilesChanged(int count);

  /// No description provided for @detailDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion · {count}'**
  String detailDiscussion(int count);

  /// No description provided for @detailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get detailNoComments;

  /// No description provided for @detailNoDiff.
  ///
  /// In en, this message translates to:
  /// **'No diff available (binary or too large). Open it in the browser.'**
  String get detailNoDiff;

  /// No description provided for @detailMoreLines.
  ///
  /// In en, this message translates to:
  /// **'… {count} more lines. Open in the browser for the full diff.'**
  String detailMoreLines(int count);

  /// No description provided for @stateOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get stateOpen;

  /// No description provided for @stateClosed.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get stateClosed;

  /// No description provided for @stateMerged.
  ///
  /// In en, this message translates to:
  /// **'merged'**
  String get stateMerged;

  /// No description provided for @stateDraft.
  ///
  /// In en, this message translates to:
  /// **'draft'**
  String get stateDraft;

  /// No description provided for @workspacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspacesTitle;

  /// No description provided for @workspaceNew.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get workspaceNew;

  /// No description provided for @workspaceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Group your work by client'**
  String get workspaceEmptyTitle;

  /// No description provided for @workspaceEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A workspace combines accounts and orgs from GitHub, GitLab or Azure DevOps under one client name, so your Inbox can show one client at a time.'**
  String get workspaceEmptyBody;

  /// No description provided for @workspaceNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get workspaceNoAccounts;

  /// No description provided for @workspaceRemovedAccount.
  ///
  /// In en, this message translates to:
  /// **'Removed account'**
  String get workspaceRemovedAccount;

  /// No description provided for @workspaceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Client / workspace name'**
  String get workspaceNameLabel;

  /// No description provided for @workspaceAccountsOrgs.
  ///
  /// In en, this message translates to:
  /// **'Accounts & orgs'**
  String get workspaceAccountsOrgs;

  /// No description provided for @workspaceOrgHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave the org field empty to include the whole account.'**
  String get workspaceOrgHelp;

  /// No description provided for @workspaceAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get workspaceAccountLabel;

  /// No description provided for @workspaceOrgLabel.
  ///
  /// In en, this message translates to:
  /// **'Org / group (optional)'**
  String get workspaceOrgLabel;

  /// No description provided for @tooltipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tooltipRemove;

  /// No description provided for @workspaceAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add account or org'**
  String get workspaceAddRule;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @connectAzureUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Organisation URL (https://dev.azure.com/your-org)'**
  String get connectAzureUrlLabel;

  /// No description provided for @connectGitlabUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Self-hosted GitLab URL (optional)'**
  String get connectGitlabUrlLabel;

  /// No description provided for @connectGiteaUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgejo / Gitea URL (e.g. https://codeberg.org)'**
  String get connectGiteaUrlLabel;

  /// No description provided for @insecureInstanceUrl.
  ///
  /// In en, this message translates to:
  /// **'This server URL uses plain http, so your token would travel unencrypted. Use https (http is allowed only for localhost and private-network addresses).'**
  String get insecureInstanceUrl;

  /// No description provided for @loadRemoteImage.
  ///
  /// In en, this message translates to:
  /// **'Load image from {host}'**
  String loadRemoteImage(String host);

  /// No description provided for @remoteImageBlocked.
  ///
  /// In en, this message translates to:
  /// **'Image blocked'**
  String get remoteImageBlocked;

  /// No description provided for @giteaNeedsUrl.
  ///
  /// In en, this message translates to:
  /// **'Forgejo / Gitea needs the server URL.'**
  String get giteaNeedsUrl;

  /// No description provided for @connectGitlabUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Empty = gitlab.com'**
  String get connectGitlabUrlHint;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal Access Token'**
  String get tokenLabel;

  /// No description provided for @enterToken.
  ///
  /// In en, this message translates to:
  /// **'Enter a token.'**
  String get enterToken;

  /// No description provided for @azureNeedsOrg.
  ///
  /// In en, this message translates to:
  /// **'Azure DevOps needs an organisation URL.'**
  String get azureNeedsOrg;

  /// No description provided for @invalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid token. Check the value and its scopes.'**
  String get invalidToken;

  /// No description provided for @couldNotConnectUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check the token and the URL.'**
  String get couldNotConnectUrl;

  /// No description provided for @couldNotConnectNet.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check the token and your internet connection.'**
  String get couldNotConnectNet;

  /// No description provided for @showToken.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get showToken;

  /// No description provided for @hideToken.
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get hideToken;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @createTokenOn.
  ///
  /// In en, this message translates to:
  /// **'Create a token on {provider}'**
  String createTokenOn(String provider);

  /// No description provided for @needsScopes.
  ///
  /// In en, this message translates to:
  /// **'Needs: {scopes}'**
  String needsScopes(String scopes);

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'One inbox for all your Git work.'**
  String get authTagline;

  /// No description provided for @authSignInGithub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with GitHub'**
  String get authSignInGithub;

  /// No description provided for @authHideOther.
  ///
  /// In en, this message translates to:
  /// **'Hide other options'**
  String get authHideOther;

  /// No description provided for @authOtherOptions.
  ///
  /// In en, this message translates to:
  /// **'GitLab, Azure DevOps or a token'**
  String get authOtherOptions;

  /// No description provided for @deviceStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Open this URL in your browser:'**
  String get deviceStep1;

  /// No description provided for @deviceStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Enter this code:'**
  String get deviceStep2;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @deviceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for authorisation…'**
  String get deviceWaiting;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @connectAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect an account'**
  String get connectAccountTitle;

  /// No description provided for @noAccountsConnected.
  ///
  /// In en, this message translates to:
  /// **'No accounts connected. Tap \"Add account\" to connect.'**
  String get noAccountsConnected;

  /// No description provided for @removeProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {provider}'**
  String removeProviderTitle(String provider);

  /// No description provided for @disconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {account}? Its repos will be removed from the list.'**
  String disconnectBody(String account);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent inbox alerts'**
  String get alertsTitle;

  /// No description provided for @alertsBody.
  ///
  /// In en, this message translates to:
  /// **'Failing CI, requested changes, conflicts and review requests. Checked in the background about every 30 minutes; iOS may run it less often.'**
  String get alertsBody;

  /// No description provided for @alertsCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get alertsCheckNow;

  /// No description provided for @alertsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. Enable it in system settings.'**
  String get alertsPermissionDenied;

  /// No description provided for @alertsCouldNotChange.
  ///
  /// In en, this message translates to:
  /// **'Could not change alerts: {error}'**
  String alertsCouldNotChange(String error);

  /// No description provided for @checkedNothing.
  ///
  /// In en, this message translates to:
  /// **'Checked — nothing new.'**
  String get checkedNothing;

  /// No description provided for @checkedNew.
  ///
  /// In en, this message translates to:
  /// **'Checked — {count, plural, one{1 new item} other{{count} new items}}.'**
  String checkedNew(int count);

  /// No description provided for @checkFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed: {error}'**
  String checkFailed(String error);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get aboutApp;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get aboutProviders;

  /// No description provided for @alertTitleMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item needs your attention} other{{count} items need your attention}}'**
  String alertTitleMany(int count);

  /// No description provided for @alertAndMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String alertAndMore(int count);

  /// No description provided for @alertChannelName.
  ///
  /// In en, this message translates to:
  /// **'Inbox alerts'**
  String get alertChannelName;

  /// No description provided for @alertChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Failing CI, review requests and other urgent items'**
  String get alertChannelDescription;

  /// No description provided for @tooltipActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tooltipActivity;

  /// No description provided for @tooltipGists.
  ///
  /// In en, this message translates to:
  /// **'Gists'**
  String get tooltipGists;

  /// No description provided for @tooltipExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore GitHub'**
  String get tooltipExplore;

  /// No description provided for @tooltipSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get tooltipSort;

  /// No description provided for @sortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get sortUpdated;

  /// No description provided for @sortStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get sortStars;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get sortCreated;

  /// No description provided for @tooltipToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get tooltipToggleTheme;

  /// No description provided for @tooltipProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tooltipProfile;

  /// No description provided for @tooltipLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get tooltipLogout;

  /// No description provided for @disconnectAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect all'**
  String get disconnectAllTitle;

  /// No description provided for @disconnectAllBody.
  ///
  /// In en, this message translates to:
  /// **'Remove all connected accounts from this device?'**
  String get disconnectAllBody;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @searchReposHint.
  ///
  /// In en, this message translates to:
  /// **'Search repositories…'**
  String get searchReposHint;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @noReposFound.
  ///
  /// In en, this message translates to:
  /// **'No repositories found'**
  String get noReposFound;

  /// No description provided for @filterOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get filterOwned;

  /// No description provided for @filterForked.
  ///
  /// In en, this message translates to:
  /// **'Forked'**
  String get filterForked;

  /// No description provided for @filterStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get filterStarred;

  /// No description provided for @filterPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get filterPublic;

  /// No description provided for @filterPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get filterPrivate;

  /// No description provided for @shortcutSearch.
  ///
  /// In en, this message translates to:
  /// **'Focus search bar'**
  String get shortcutSearch;

  /// No description provided for @shortcutRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh repositories'**
  String get shortcutRefresh;

  /// No description provided for @shortcutHelp.
  ///
  /// In en, this message translates to:
  /// **'Show this dialog'**
  String get shortcutHelp;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get shortcutsTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @repoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 repository} other{{count} repositories}}'**
  String repoCount(int count);

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @browseCode.
  ///
  /// In en, this message translates to:
  /// **'Browse code'**
  String get browseCode;

  /// No description provided for @unstar.
  ///
  /// In en, this message translates to:
  /// **'Unstar'**
  String get unstar;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get star;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @pullRequests.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get pullRequests;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @commits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get commits;

  /// No description provided for @releases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releases;

  /// No description provided for @forkLabel.
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get forkLabel;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @recentCommits.
  ///
  /// In en, this message translates to:
  /// **'Recent commits'**
  String get recentCommits;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noCommitsFound.
  ///
  /// In en, this message translates to:
  /// **'No commits found'**
  String get noCommitsFound;

  /// No description provided for @forks.
  ///
  /// In en, this message translates to:
  /// **'Forks'**
  String get forks;

  /// No description provided for @watchers.
  ///
  /// In en, this message translates to:
  /// **'Watchers'**
  String get watchers;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @contributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get contributors;

  /// No description provided for @clone.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get clone;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @openOnProvider.
  ///
  /// In en, this message translates to:
  /// **'Open on {provider}'**
  String openOnProvider(String provider);

  /// No description provided for @contributorTooltip.
  ///
  /// In en, this message translates to:
  /// **'{login} · {count, plural, one{1 commit} other{{count} commits}}'**
  String contributorTooltip(String login, int count);

  /// No description provided for @noProfileData.
  ///
  /// In en, this message translates to:
  /// **'No profile data'**
  String get noProfileData;

  /// No description provided for @reposLabel.
  ///
  /// In en, this message translates to:
  /// **'Repos'**
  String get reposLabel;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @searchAllHint.
  ///
  /// In en, this message translates to:
  /// **'Search all GitHub repositories…'**
  String get searchAllHint;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @searchAcrossTitle.
  ///
  /// In en, this message translates to:
  /// **'Search across all of GitHub'**
  String get searchAcrossTitle;

  /// No description provided for @searchAcrossBody.
  ///
  /// In en, this message translates to:
  /// **'Find repos by name, topic, or description'**
  String get searchAcrossBody;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @failedLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedLoadNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @reasonSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get reasonSubscribed;

  /// No description provided for @reasonAssignedShort.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get reasonAssignedShort;

  /// No description provided for @reasonAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get reasonAuthor;

  /// No description provided for @reasonCommented.
  ///
  /// In en, this message translates to:
  /// **'Commented'**
  String get reasonCommented;

  /// No description provided for @reasonTeamMention.
  ///
  /// In en, this message translates to:
  /// **'Team mentioned'**
  String get reasonTeamMention;

  /// No description provided for @reasonStateChange.
  ///
  /// In en, this message translates to:
  /// **'State changed'**
  String get reasonStateChange;

  /// No description provided for @failedLoadActivity.
  ///
  /// In en, this message translates to:
  /// **'Failed to load activity'**
  String get failedLoadActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @yourGists.
  ///
  /// In en, this message translates to:
  /// **'Your Gists'**
  String get yourGists;

  /// No description provided for @failedLoadGists.
  ///
  /// In en, this message translates to:
  /// **'Failed to load gists'**
  String get failedLoadGists;

  /// No description provided for @noGistsYet.
  ///
  /// In en, this message translates to:
  /// **'No gists yet'**
  String get noGistsYet;

  /// No description provided for @gistSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get gistSecret;

  /// No description provided for @newIssue.
  ///
  /// In en, this message translates to:
  /// **'New issue'**
  String get newIssue;

  /// No description provided for @tabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tabOpen;

  /// No description provided for @tabClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get tabClosed;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @tabMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get tabMerged;

  /// No description provided for @joinedAgo.
  ///
  /// In en, this message translates to:
  /// **'Joined {time}'**
  String joinedAgo(String time);

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @reposForQuery.
  ///
  /// In en, this message translates to:
  /// **'{count}+ repositories for \"{query}\"'**
  String reposForQuery(int count, String query);

  /// No description provided for @updatedAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAgo(String time);

  /// No description provided for @noOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'No open issues'**
  String get noOpenIssues;

  /// No description provided for @noClosedIssues.
  ///
  /// In en, this message translates to:
  /// **'No closed issues'**
  String get noClosedIssues;

  /// No description provided for @noOpenPrs.
  ///
  /// In en, this message translates to:
  /// **'No open pull requests'**
  String get noOpenPrs;

  /// No description provided for @noClosedPrs.
  ///
  /// In en, this message translates to:
  /// **'No closed pull requests'**
  String get noClosedPrs;

  /// No description provided for @noMergedPrs.
  ///
  /// In en, this message translates to:
  /// **'No merged pull requests'**
  String get noMergedPrs;

  /// No description provided for @openedAgo.
  ///
  /// In en, this message translates to:
  /// **'opened {time}'**
  String openedAgo(String time);

  /// No description provided for @closedAgo.
  ///
  /// In en, this message translates to:
  /// **'closed {time}'**
  String closedAgo(String time);

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String byAuthor(String author);

  /// No description provided for @prOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get prOpen;

  /// No description provided for @prMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get prMerged;

  /// No description provided for @prClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get prClosed;

  /// No description provided for @prDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get prDraft;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @noCommitsOnBranch.
  ///
  /// In en, this message translates to:
  /// **'No commits on this branch'**
  String get noCommitsOnBranch;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get defaultBadge;

  /// No description provided for @noReleasesYet.
  ///
  /// In en, this message translates to:
  /// **'No releases yet'**
  String get noReleasesYet;

  /// No description provided for @viewOnGithub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGithub;

  /// No description provided for @copyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy content'**
  String get copyContent;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @binaryFile.
  ///
  /// In en, this message translates to:
  /// **'Binary file — cannot display'**
  String get binaryFile;

  /// No description provided for @emptyDirectory.
  ///
  /// In en, this message translates to:
  /// **'Empty directory'**
  String get emptyDirectory;

  /// No description provided for @noReadmeFound.
  ///
  /// In en, this message translates to:
  /// **'No README found'**
  String get noReadmeFound;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @describeIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue… (optional)'**
  String get describeIssueHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @submitIssue.
  ///
  /// In en, this message translates to:
  /// **'Submit issue'**
  String get submitIssue;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @emptyComment.
  ///
  /// In en, this message translates to:
  /// **'(empty comment)'**
  String get emptyComment;

  /// No description provided for @prTitle.
  ///
  /// In en, this message translates to:
  /// **'PR #{number}'**
  String prTitle(int number);

  /// No description provided for @issueTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue #{number}'**
  String issueTitle(int number);

  /// No description provided for @releasedAgo.
  ///
  /// In en, this message translates to:
  /// **'released {time}'**
  String releasedAgo(String time);

  /// No description provided for @committedAgo.
  ///
  /// In en, this message translates to:
  /// **'committed {time}'**
  String committedAgo(String time);

  /// No description provided for @commentedAgo.
  ///
  /// In en, this message translates to:
  /// **'commented {time}'**
  String commentedAgo(String time);

  /// No description provided for @filesChangedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file changed} other{{count} files changed}}'**
  String filesChangedCount(int count);

  /// No description provided for @commentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 comment} other{{count} comments}}'**
  String commentCount(int count);

  /// No description provided for @errInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired token. Please reconnect.'**
  String get errInvalidToken;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden. Check your token scopes.'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get errNotFound;

  /// No description provided for @errTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again in a moment.'**
  String get errTooMany;

  /// No description provided for @errInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Check the data and try again.'**
  String get errInvalidRequest;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'The server is having issues. Try again later.'**
  String get errServer;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error ({code}).'**
  String errUnexpected(String code);

  /// No description provided for @errCommentRequired.
  ///
  /// In en, this message translates to:
  /// **'A comment is required to request changes.'**
  String get errCommentRequired;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'GitHub is rate limiting requests. Try again in a minute.'**
  String get errRateLimited;

  /// No description provided for @errRateLimitedIn.
  ///
  /// In en, this message translates to:
  /// **'GitHub is rate limiting requests. Try again in {seconds}s.'**
  String errRateLimitedIn(String seconds);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
