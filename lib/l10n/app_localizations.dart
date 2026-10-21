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
