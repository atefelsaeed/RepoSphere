> **Historical backlog (April–June 2026).** Kept for context; the roadmap now lives in the [README](../README.md#status-and-roadmap) and releases are described in the [CHANGELOG](../CHANGELOG.md).

# RepoSphere — Improvements Backlog
> Last updated: June 2026

Tracked items needed to bring RepoSphere to a world-class, shippable standard.
Each item has a status tag: `[ ]` pending · `[x]` done · `[-]` skipped/deferred.

---

## Sprint 6 — Unified Multi-Provider Architecture

Goal: turn RepoSphere from a GitHub-only viewer into a true multi-provider Git
workspace (GitHub + GitLab + Azure DevOps now; Bitbucket + Gitea/self-hosted next).

### S6-1 · Capability-based `GitProvider` interface `[x]`
**Why:** the old interface had only 3 methods and most screens bypassed it,
calling `GitHubRemoteDatasource` directly — there was no real abstraction.

**Delivered:**
- `GitProviderType` enum (single source of truth, shared by auth + repos)
- `ProviderCapabilities` so the UI can hide unsupported features
- Full `GitProvider` surface (repos, branches, commits + diff, PRs/MRs,
  issues/work-items, comments, releases, file tree + content, languages,
  contributors, search, writes, notifications, activity, gists)
- `UnsupportedProviderOperation` for ops a provider can't perform

**Files:** `core/git/git_provider_type.dart`,
`features/repos/domain/repositories/git_provider.dart`

### S6-2 · Multi-account connections + secure storage `[x]`
**Why:** tokens were single-account per provider, hardcoded keys.

**Delivered:**
- `GitConnection` model (type, account, baseUrl for self-hosted/Azure, token)
- `SecureTokenStorage` stores a JSON connection list + one-time migration of
  legacy `github_pat` / `gitlab_pat`
- `connectionsProvider` (`ConnectionsNotifier`: add / remove / update)

**Files:** `features/auth/domain/git_connection.dart`,
`features/auth/data/secure_token_storage.dart`,
`features/auth/presentation/providers/connections_provider.dart`

### S6-3 · Provider factory / registry `[x]`
**Delivered:** `buildGitProvider(connection)` + `activeProvidersProvider`,
`providerForConnectionProvider`, `providerForRepoProvider` (routes a repo to the
adapter that owns it via `connectionId` / `providerId`).

**Files:** `features/repos/data/git_provider_factory.dart`,
`RepoEntity` (+ `connectionId`, `providerId`, `GitProviderType provider`)

### S6-4 · GitHub adapter — full read + write `[x]`
**Delivered:** `GitHubRepoRepositoryImpl` wraps the whole datasource; added
write ops `addIssueComment`, `mergePullRequest`, `setIssueState`.

### S6-5 · GitLab adapter — full read `[x]`
**Delivered:** expanded `GitLabRemoteDatasource` to a full v4 client +
`GitLabRepoRepositoryImpl` (projects, branches, commits + diff, MRs, issues,
notes, releases, tree, files, todos, events; self-hosted base URL).

### S6-6 · Azure DevOps adapter — read (proof) `[x]`
**Delivered:** `AzureRemoteDatasource` (Basic auth, org/project/repo, items,
WIQL) + `AzureRepoRepositoryImpl` (repos, commits, PRs, **Work Items**, files).

### S6-7 · Tests + quality gate `[x]`
**Delivered:** unit tests for `GitConnection`, GitLab adapter, Azure adapter
(MockClient) — 27 tests green, `flutter analyze` clean, web build passing.

### S6-8 · UI wiring — multi-account connect + unified list `[x]`
**Delivered:**
- Auth + router gate on `connectionsProvider` (any provider can be the first
  account — GitHub no longer required).
- Settings rewritten: lists every connected account with a provider badge,
  **Add account** sheet (GitHub / GitLab / Azure DevOps, with base/org URL for
  GitLab self-hosted and Azure) that verifies the token before saving, and
  per-account remove.
- Auth screen connects by adding a `GitConnection` (verifies via `/user`).
- Unified repos list: `allReposProvider` aggregates `activeProvidersProvider`
  across every account; cards show a provider badge (GL/AZ/…).
- `githubDatasourceProvider` / GitLab datasource now sourced from the first
  connection of their type, so existing detail screens work without rewiring.
- Repo detail hides GitHub-only sections for any non-GitHub repo.

**Files:** `app.dart`, `main.dart`, `core/router/app_router.dart`,
`auth_screen.dart`, `connections_provider.dart`, `repos_provider.dart`,
`repos_screen.dart`, `settings_screen.dart`, `repo_detail_screen.dart`,
`repo_card.dart`.

### S6-9 · UI wiring — deep per-provider detail + writes `[ ]`
**Remaining:** route each per-repo detail provider (commits/PRs/issues/files/…)
through `providerForRepoProvider` so GitLab/Azure repos show full detail (not
just GitHub); surface GitHub write actions (comment, merge PR, close issue) in
the PR/issue screens; "My Work" cross-provider screen (assigned PRs/issues);
per-account (not first-of-type) routing for multiple accounts of one provider.

---

## Sprint 1 — Blockers

### S1-1 · Settings screen + Provider management `[x]`
**Why:** GitLab token had no entry point in the UI.

**Delivered:**
- `/settings` named route → `SettingsScreen`
- GitHub card: avatar + login + Connected badge + Disconnect
- GitLab card: PAT entry form with verify → connected state + Disconnect
- Appearance section: System / Light / Dark segmented button
- Gear icon added to repos AppBar

**Files:** `settings_screen.dart`, `app_router.dart`, `repos_screen.dart`

---

### S1-2 · `_checkResponse` — handle all HTTP status codes `[x]`
**Why:** Non-2xx responses fell through to a raw status-code string shown to the user.

**Delivered:**
- 401 → `GitHubAuthException` "Invalid or expired token."
- 403 + rate-limit header → `GitHubRateLimitException` with reset time
- 403 otherwise → "Access forbidden. Check your token scopes."
- 404 → "Resource not found."
- 422 → "Invalid request."
- 429 → `GitHubRateLimitException`
- 5xx → "GitHub is having issues."
- default → "Unexpected error (NNN)."

**Files:** `github_remote_datasource.dart`, `exceptions.dart`

---

### S1-3 · Token expiry → auto logout `[x]`
**Why:** Expired tokens caused scattered API error states across all screens.

**Delivered:**
- `_AuthErrorObserver extends ProviderObserver` in `main.dart`
- `providerDidFail()` intercepts any `GitHubAuthException` globally
- Calls `authProvider.notifier.logout()` → router guard redirects to `/auth`

**Files:** `main.dart`

---

## Sprint 2 — Quality

### S2-1 · Notifications badge count `[x]`
**Why:** Bell icon showed no unread count.

**Delivered:**
- `notificationsProvider` watched in `repos_screen.dart`
- Material 3 `Badge` widget wraps the bell icon
- Shows count (or "99+") only when unread > 0

**Files:** `repos_screen.dart`

---

### S2-2 · Commit diff view `[x]`
**Why:** CommitDetailScreen showed file names + counts but no actual diff.

**Delivered:**
- `_FileTile` converted to `StatefulWidget` with expand/collapse on tap
- `_DiffView` widget parses unified diff line-by-line:
  - `+` lines → green background / text (dark + light variants)
  - `-` lines → red background / text
  - `@@` hunk headers → blue
  - Context lines → muted
- Monospace font, horizontal scroll for long lines
- Chevron icon in file header indicates expand state

**Note:** `patch` field was already present in `CommitFileChange` — only
the screen needed updating.

**Files:** `commit_detail_screen.dart`

---

### S2-3 · Repos infinite scroll / pagination `[x]`
**Why:** `getRepos()` fetched all repos in one call. Users with 200+ repos
only saw the first batch.

**Delivered:**
- `getRepos(page, perPage)` added to `GitHubRemoteDatasource`
- `ReposNotifier` (StateNotifierProvider) with state: repos, isLoading,
  isLoadingMore, hasMore, error — 30 repos/page
- `allReposProvider` changed from `FutureProvider` to
  `Provider<AsyncValue<T>>` combining notifier state + `gitlabReposProvider`
- `ScrollController` in ReposScreen triggers `loadMore()` 300 px before bottom
- Spinner footer while loading; "all repos loaded" message when exhausted
- `_refresh()` calls `notifier.refresh()` instead of invalidating providers

**Files:** `github_remote_datasource.dart`, `repos_notifier.dart` (new),
`repos_provider.dart`, `repos_screen.dart`, `settings_screen.dart`

---

### S2-4 · File browser branch selector `[x]`
**Why:** File browser always showed the default branch.

**Delivered:**
- `RepoBrowserScreen` converted to `ConsumerStatefulWidget`
- `initialBranch` constructor param; `_selectedBranch` local state
- `_BranchSelector` dropdown in AppBar watches `repoBranchesProvider`
- Default branch shown with a "default" badge in the dropdown
- Branch change resets path to root and re-fetches contents
- Branch preserved through breadcrumb navigation and folder taps
- `getContents(owner, repo, path, {String? ref})` updated in datasource
- GoRouter extra record updated to `({RepoEntity repo, String path, String? branch})`

**Files:** `repo_browser_screen.dart`, `repo_contents_provider.dart`,
`github_remote_datasource.dart`, `app_router.dart`, `repo_detail_screen.dart`

---

## Sprint 3 — Polish

### S3-1 · App icon (all platforms) `[ ]`
**Why:** Default Flutter icon looks unprofessional.

**Scope:**
- Design icon (hub/sphere concept matching the splash screen gradient)
- Add `flutter_launcher_icons` to `pubspec.yaml`
- Generate icons for: iOS, Android, macOS, Windows, Linux, Web (favicon + 192/512)

**Blocked by:** needs design assets (PNG source file 1024×1024).

---

### S3-2 · Keyboard navigation `[x]`
**Why:** Web and desktop users expect keyboard shortcuts beyond just `/`.

**Delivered:**
- **Global `Escape` → back:** `CallbackShortcuts` + `Focus(autofocus: true)`
  wraps `MaterialApp.router` in `app.dart`; calls `router.pop()` when canPop
- **`/`** → focus search bar (already existed)
- **`R`** → refresh repos list
- **`?`** → `_ShortcutsDialog` with styled keyboard badge UI listing all shortcuts
- Tab / Shift+Tab traversal handled natively by Flutter

**Files:** `app.dart`, `repos_screen.dart`

---

### S3-3 · User-friendly error messages `[x]`
**Why:** Raw exception strings were reaching the UI.

**Delivered:**
- `ErrorView` takes `Object error` — smart icon + color per type:
  - `GitHubAuthException` → lock icon, error color
  - `GitHubRateLimitException` → hourglass, amber
  - `GitHubApiException` → cloud-off, surface variant
  - Unknown → strips "Exception:" / "GitHubApiException:" prefixes
- `ErrorView.message(String)` named constructor for legacy call sites
- All `.when(error: ...)` sites audited — last raw `Text('Failed to load commits: $e')`
  in `repo_detail_screen.dart` replaced with `ErrorView(error: e)`

**Files:** `error_view.dart`, all `.when(error:)` call sites

---

### S3-4 · Web meta tags + PWA manifest `[x]`
**Why:** Sharing a link showed no preview; the app wasn't installable as a PWA.

**Delivered:**
- `web/index.html`: `<title>RepoSphere</title>`, description meta, Open Graph
  (og:title, og:description, og:image, og:type, og:site_name), Twitter Card,
  apple-touch-icon, `theme-color: #6750A4`, lang="en"
- `web/manifest.json`: name "RepoSphere", description, `background_color: #131318`,
  `theme_color: #6750A4`, `orientation: any`, `categories: [developer, productivity]`

**Files:** `web/index.html`, `web/manifest.json`

---

## Sprint 4 — Scale

### S4-1 · Unit + widget tests `[x]`
**Why:** Zero test coverage meant regressions went undetected.

**Delivered (12 unit tests, all passing):**

`test/unit/repo_model_test.dart`:
- Parses all fields correctly from JSON fixture
- Sets `provider = RepoProvider.github` on `toEntity()`
- Handles null optional fields (description, language, defaultBranch, topics)
- Defaults missing count fields to 0

`test/unit/github_datasource_test.dart`:
- Sends correct `Authorization: token …` header
- Parses list response into model list
- Sends `page` + `per_page` query params correctly
- Throws `GitHubAuthException` on 401
- Throws `GitHubRateLimitException` on 429
- Throws `GitHubApiException` on 404
- `getContents` passes `ref` param when branch given
- `getContents` omits `ref` param when branch is null

Uses `http/testing.dart` `MockClient` — no additional test packages needed.

**Files:** `test/unit/repo_model_test.dart`, `test/unit/github_datasource_test.dart`

---

### S4-2 · GitHub Actions CI pipeline `[x]`
**Why:** No automated checks on PRs.

**Delivered:** `.github/workflows/ci.yml` with three jobs:
- **analyze** — `dart analyze lib/ --fatal-infos`
- **test** — `flutter test --coverage`
- **build-web** — `flutter build web --release`; uploads artifact (7-day retention)

`build-web` only runs after `analyze` + `test` both pass.
Uses `subosito/flutter-action@v2` with Flutter 3.24.x stable and caching.

**Files:** `.github/workflows/ci.yml`

---

### S4-3 · Crash reporting (Sentry) `[x]`
**Why:** No visibility into production crashes.

**Delivered:**
- `sentry_flutter: ^8.12.0` added to `pubspec.yaml`
- `AppConfig.sentryDsn` reads from `--dart-define=SENTRY_DSN=…` at build time
- `main.dart`: if DSN is set → `SentryFlutter.init()` wraps `runApp`;
  otherwise runs normally (zero-cost when DSN is absent)
- `tracesSampleRate: 0.2`, environment set from `dart.vm.product`

**To activate:** `flutter build web --dart-define=SENTRY_DSN=<your-dsn>`

**Files:** `pubspec.yaml`, `main.dart`, `lib/core/config/app_config.dart`

---

### S4-4 · Internationalization (i18n) `[ ]`
**Why:** All strings are hardcoded in English.

**Scope:**
- Add `flutter_localizations` + `intl` packages
- Extract all user-visible strings to ARB files (`lib/l10n/app_en.arb`)
- Support: English (default), Arabic (RTL)
- RTL layout support via `Directionality` widget

**Note:** Large scope — requires touching every screen and widget file.

---

## Sprint 5 — Multi-Account Support

### S5-1 · Account model + storage `[ ]`
**Why:** SecureStorage currently holds a single token per provider. Supporting
multiple companies/identities requires a structured account list.

**Scope:**
- Introduce `Account` model: `{ id (uuid), provider (github|gitlab), label, token }`
- `SecureTokenStorage` stores `List<Account>` serialised as JSON under a single key
- Migration: on first launch after update, wrap the existing GitHub / GitLab
  tokens into `Account` objects so existing users aren't logged out
- Add `accountsProvider` (StateNotifierProvider) with `AccountsNotifier`:
  - `add(provider, label, token)` — verifies token before saving
  - `remove(id)` — deletes account and invalidates its repos
  - `list` — all connected accounts

**Files:**
- `lib/features/auth/data/models/account_model.dart` (new)
- `lib/features/auth/data/secure_token_storage.dart`
- `lib/features/auth/presentation/providers/accounts_provider.dart` (new)

---

### S5-2 · Per-account datasources `[ ]`
**Why:** `githubDatasourceProvider` / `gitlabDatasourceProvider` return a
single datasource. With multiple accounts each needs its own authenticated client.

**Scope:**
- `githubDatasourcesProvider` → `List<({Account account, GitHubRemoteDatasource ds})>`
- `gitlabDatasourcesProvider` → `List<({Account account, GitLabRemoteDatasource ds})>`
- Both derived from `accountsProvider` — rebuild automatically when accounts change
- `_AuthErrorObserver` maps auth failures back to the correct account and removes only that one

**Files:**
- `lib/features/repos/presentation/providers/repos_provider.dart`

---

### S5-3 · Fan-out repo fetching `[ ]`
**Why:** `allReposProvider` and `ReposNotifier` are wired to a single datasource.
Multiple accounts need fan-out: fetch from each, merge, deduplicate.

**Scope:**
- `ReposNotifier` accepts `List<datasource>` instead of a single one
- Fetches page N from each account in parallel (`Future.wait`)
- Merges results; `hasMore` is true as long as any account has more pages
- `RepoEntity` gains `accountId` (String) and `accountLabel` (String) fields
- Deduplication: same repo id from same provider+account is not duplicated on refresh

**Files:**
- `lib/features/repos/presentation/providers/repos_notifier.dart`
- `lib/features/repos/domain/entities/repo_entity.dart`
- `lib/features/repos/data/models/repo_model.dart`
- `lib/features/repos/data/datasources/gitlab_remote_datasource.dart`

---

### S5-4 · Account badge in UI `[ ]`
**Why:** With repos from multiple accounts in one list, users need to know
which account each repo belongs to.

**Scope:**
- `RepoCard` shows a small avatar or coloured dot in the bottom-right corner
  labelled with the account's `label` field on hover/tap
- `RepoDetailScreen` AppBar subtitle shows `accountLabel` next to the provider icon
- Filter chip "All" shows total; add per-account filter chips dynamically from `accountsProvider`
- Pinned chip shows account label in a secondary line

**Files:**
- `lib/features/repos/presentation/widgets/repo_card.dart`
- `lib/features/repos/presentation/screens/repo_detail_screen.dart`
- `lib/features/repos/presentation/screens/repos_screen.dart`

---

### S5-5 · Accounts management UI `[ ]`
**Why:** Settings screen currently handles one GitHub + one GitLab account.
Multi-account needs a proper list with add/remove per account.

**Scope:**
- Settings → "Connected Accounts" section replaces the current two cards
- Each connected account shows: provider icon, label (editable), login/username,
  "Connected" badge, Remove button
- "Add GitHub account" button → PAT entry form with label field + Verify + Connect
- "Add GitLab account" button → same flow
- No limit on number of accounts
- Confirm dialog on remove (warns that all repos from that account will disappear)

**Files:**
- `lib/features/repos/presentation/screens/settings_screen.dart`

---

## Status Summary

| ID    | Item                          | Sprint | Status |
|-------|-------------------------------|--------|--------|
| S1-1  | Settings + GitLab UI          | 1      | [x]    |
| S1-2  | `_checkResponse` all codes    | 1      | [x]    |
| S1-3  | Token expiry → auto logout    | 1      | [x]    |
| S2-1  | Notifications badge           | 2      | [x]    |
| S2-2  | Commit diff view              | 2      | [x]    |
| S2-3  | Repos pagination              | 2      | [x]    |
| S2-4  | File browser branch selector  | 2      | [x]    |
| S3-1  | App icon all platforms        | 3      | [ ]    |
| S3-2  | Keyboard navigation           | 3      | [x]    |
| S3-3  | User-friendly errors          | 3      | [x]    |
| S3-4  | Web meta tags + PWA manifest  | 3      | [x]    |
| S4-1  | Unit + widget tests           | 4      | [x]    |
| S4-2  | GitHub Actions CI             | 4      | [x]    |
| S4-3  | Crash reporting (Sentry)      | 4      | [x]    |
| S4-4  | i18n / Arabic RTL             | 4      | [ ]    |
| S5-1  | Account model + storage       | 5      | [ ]    |
| S5-2  | Per-account datasources       | 5      | [ ]    |
| S5-3  | Fan-out repo fetching         | 5      | [ ]    |
| S5-4  | Account badge in UI           | 5      | [ ]    |
| S5-5  | Accounts management UI        | 5      | [ ]    |
