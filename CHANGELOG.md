# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/) (pre-1.0: minor versions may include breaking changes).

## [Unreleased]

### Documentation
- Rewritten README for newcomers (what it is, why, install, quick start, provider table, privacy), an Arabic README, and new guides in `doc/`: getting started (tokens per provider), user guide, FAQ / troubleshooting and architecture. More screenshots. The old spec and backlog are marked as historical.

## [0.3.0] — 2026-10-21

**First published release.** RepoSphere answers "what needs me today?" across all your Git accounts: one prioritised Inbox for GitHub, GitLab (including self-hosted), Azure DevOps and Forgejo / Gitea with failing CI, requested changes, conflicts, review requests, assignments and mentions; open an item to read its diff and discussion; approve / request changes / merge / re-run CI from the item; client workspaces; urgent alerts on mobile; Arabic and English. Builds for web, macOS, Windows, Linux and Android. Version 0.2.0 was prepared but never tagged, so its changes are included here (see below).

### Added
- **Forgejo / Gitea** (including Codeberg and self-hosted servers): Inbox, in-app detail with diff, approve, request changes and merge. Choose it on the login screen or in Settings.
- **Azure DevOps**: approve, request changes, merge, and in-app detail (changed files and discussion for PRs; description and comments for work items).
- **In-app detail** for Inbox items (GitHub, GitLab, Azure DevOps, Forgejo / Gitea): description, changed files with a coloured unified diff (Azure lists files without line counts), and the discussion, with the quick actions one tap away.
- **Arabic and English**, with full right-to-left layout, across the Inbox, item detail, quick actions, workspaces, login/connect form, Settings, the repository browser, provider error messages and the background alert notifications. Pick the language in Settings (default: your device language). A test guards against new hard-coded English labels.
- Inbox now tells you when **some results may be missing** (a query failed while others succeeded) and why, instead of showing a partial list silently.
- Widget tests for the Inbox, detail and error screens.

### Changed
- Tapping an Inbox item opens its detail; long-press (or the Actions button in the detail) opens the quick-action sheet. Swipe gestures are unchanged.
- GitHub search results are paged (up to 200 per query) instead of stopping at the first 50.
- Errors name the real reason, e.g. "GitHub is rate limiting requests. Try again in 42s." (secondary rate limits used to read "Access forbidden").
- The in-app detail hides the `+0 −0` counter for providers that list changed files without line counts.

### Fixed
- GitLab: a merge request whose pipeline was still running or not started was reported as "CI failed". The head pipeline is now checked.

## [0.2.0] — 2026-10-21 (never tagged; shipped in 0.3.0)

First release of the unified Inbox: RepoSphere now answers "what needs me today?" across all your Git accounts.

### Added
- Login screen now lets you choose GitHub, GitLab or Azure DevOps (it was GitHub-only), with a link to create a token and the scopes each needs. The same form is used in Settings.
- New app icon (the hub mark) for iOS, Android (adaptive), macOS, Windows and web; regenerate with `tool/make_icon.py` + `dart run flutter_launcher_icons`.
- Web: updated metadata and PWA manifest (works from a sub-path); the existing `deploy-web.yml` Pages workflow now builds with Flutter 3.41.
- Release workflow that builds web, macOS, Windows, Linux and Android artifacts and attaches them to a `v*` tag release; CI now also builds the desktop apps and Android.
- MIT `LICENSE`.
- **Unified Inbox** as the home screen: failing CI, requested changes, merge conflicts, review requests, assignments and mentions from every connected GitHub, GitLab (including self-hosted) and Azure DevOps account, merged and prioritised.
- **Quick actions** on inbox PRs/MRs: approve, request changes, merge, re-run failed CI (per provider capability; confirmation for approve and merge).
- **Done and snooze**: swipe to mark done (returns on new activity) or snooze for 4 hours, a day or a week.
- **Filters** by reason (with counts), account and workspace.
- **Workspaces**: group whole accounts and/or specific orgs or groups under a client name and colour; the Inbox can be filtered per client and items are tagged with theirs.
- **Offline-friendly Inbox**: opens from the last snapshot, and shows a banner naming any account that failed instead of silently hiding it.
- **Urgent inbox alerts (iOS/Android)**: optional background check with local notifications for newly urgent items only, a Settings toggle with permission request, and a "Check now" button.
- Azure DevOps inbox: unreviewed PRs, your PRs with rejections or conflicts, and assigned work items.

### Changed
- macOS: the app no longer requires a development certificate to build. It now uses the classic keychain instead of the data-protection keychain (which needed a signed keychain-sharing entitlement). Tokens saved by an earlier macOS build are not carried over — reconnect your accounts.
- Display name is now "RepoSphere" on every platform (was `repo_sphere` / "Repo Sphere").
- iOS: saved connections are migrated once to the `first_unlock` keychain class so background checks can read tokens while the phone is locked. The migration verifies a backup copy first, never throws and retries on the next launch.
- iOS minimum deployment target raised from 13.0 to 14.0 (required by Workmanager).
- `sentry_flutter` upgraded from 8.x to 9.x.
- CI now builds with a current stable Flutter instead of 3.24.

### Fixed
- Check marks on selected filter chips were invisible in the light theme, and the workspace chip's colour dot was hidden when selected.
- Self-hosted GitLab could not be added from the UI: the instance URL field was never shown for GitLab. It now is (optional), and URLs typed without `https://` are normalised.
- Android release builds had no `INTERNET` permission in the main manifest, so they could not reach any Git host.
- Android builds failed to compile because `sentry_flutter` 8.x did not support the project's Kotlin version.
- Chip labels were unreadable in the dark theme.

### Known issues
- Azure DevOps has no inbox mentions, CI status or PR actions yet; GitLab cannot "request changes".
- Alerts depend on the OS scheduling background work; iOS may run them infrequently.
- Workspaces, snoozes and the Inbox cache are local to the device.

## [0.1.0] — 2026-06-21

First multi-provider milestone (the state of `pubspec.yaml` version `0.1.0`).

### Added
- **Unified multi-provider layer**: capability-based `GitProvider` interface with GitHub (read and write), GitLab (read) and Azure DevOps (read, including work items via WIQL) adapters; multi-account connections stored in secure storage with migration from the old single-token keys.
- Repo browser: repos with filter/sort/search/pagination, file tree with branch selector and syntax highlighting, commits with diffs, PRs/MRs and issues/work items with comment threads, releases, activity, notifications, gists, global search, profile, repo pinning, create issue.
- Settings screen with account management, auto-logout on token expiry, friendly error messages, keyboard navigation, PWA manifest.
- GitHub Actions CI (analyze, test, web build), unit tests, optional Sentry crash reporting.

## History before 0.1.0

Development began on 2026-04-22 as a GitHub-only dashboard (phases 1–3 and sprints 1–4 in [doc/IMPROVEMENTS.md](doc/IMPROVEMENTS.md)) and became multi-provider in June 2026.
