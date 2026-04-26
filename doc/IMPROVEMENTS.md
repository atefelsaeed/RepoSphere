# RepoSphere — Improvements Backlog
> Last updated: April 2026

Tracked items needed to bring RepoSphere to a world-class, shippable standard.
Each item has a status tag: `[ ]` pending · `[x]` done · `[-]` skipped/deferred.

---

## Sprint 1 — Blockers

### S1-1 · Settings screen + Provider management
**Why:** GitLab token has no entry point in the UI. Users can't connect GitLab,
disconnect any provider, or manage their account. This is a hard blocker for
multi-provider support being actually usable.

**Scope:**
- New `/settings` named route → `SettingsScreen`
- "Connected Providers" section:
  - GitHub: shows avatar + login + "Connected" badge + Disconnect button
  - GitLab: shows "Connect" form (PAT entry + verify) OR connected state + Disconnect
- "Appearance" section: theme toggle (already exists, move here too)
- Entry point: gear icon in repos AppBar + profile screen

**Files:**
- `lib/features/repos/presentation/screens/settings_screen.dart` (new)
- `lib/core/router/app_router.dart` (add `/settings` route)
- `lib/features/repos/presentation/screens/repos_screen.dart` (add gear icon)
- `lib/features/auth/data/secure_token_storage.dart` (already has GitLab read/write)

---

### S1-2 · `_checkResponse` — handle all HTTP status codes
**Why:** Any non-200/401/403 response falls into a generic "Request failed with
status NNN" message shown raw to the user.

**Scope:** Update `GitHubRemoteDatasource._checkResponse()`:
```
200 → ok (current)
201 → ok (already handled separately in createIssue)
204 → ok (already handled in isStarred, contributors)
401 → GitHubAuthException — "Invalid or expired token. Please reconnect."
403 → check X-RateLimit-Remaining header:
       0 → GitHubRateLimitException — "Rate limit exceeded. Resets at HH:MM."
       else → "Access forbidden. Check your token scopes."
404 → GitHubApiException — "Not found."
422 → GitHubApiException — "Invalid request. Check the data and try again."
429 → GitHubRateLimitException — "Too many requests. Try again in a moment."
5xx → GitHubApiException — "GitHub is having issues. Try again later."
default → GitHubApiException — "Unexpected error (status NNN)."
```

**Files:**
- `lib/features/repos/data/datasources/github_remote_datasource.dart`
- `lib/core/utils/exceptions.dart` (may need new exception types)

---

### S1-3 · Token expiry → auto logout
**Why:** If a stored token is revoked or expired, every screen shows scattered
API error states instead of redirecting the user to re-authenticate.

**Scope:**
- Add a global `GitHubAuthException` listener in `AuthNotifier`
- When any provider catches `GitHubAuthException`, call `authProvider.notifier.logout()`
- The router redirect guard already handles `token == null` → `/auth`
- Show a one-time SnackBar: "Session expired. Please reconnect."

**Approach:** Override `ProviderObserver` or add a catchError wrapper in the
datasource that re-throws after signaling the auth notifier.

**Files:**
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/core/router/app_router.dart` (may need observer wiring)

---

## Sprint 2 — Quality

### S2-1 · Notifications badge count
**Why:** The bell icon in the AppBar shows no unread count. This is a standard
UX pattern — users expect a red badge.

**Scope:**
- Watch `notificationsProvider` in `repos_screen.dart`
- Wrap the bell `IconButton` in a `Stack` with a `Badge` widget
- Show count only when unread > 0; show "99+" when > 99
- Badge disappears after "Mark all read"

**Files:**
- `lib/features/repos/presentation/screens/repos_screen.dart`

---

### S2-2 · Commit diff view
**Why:** `CommitDetailScreen` shows file names and +/- counts but no actual
code diff. Users have to go to GitHub to read the changes.

**Scope:**
- GitHub API already returns `patch` field per file in commit detail response
- `CommitDetailModel` / `CommitDetailEntity` need a `patch` field per file
- In `CommitDetailScreen`, tapping a file expands an inline diff view:
  - Red lines for deletions (prefix `-`)
  - Green lines for additions (prefix `+`)
  - Gray lines for context
  - Monospace font, horizontal scroll
- Collapsed by default; tap file row to expand/collapse

**Files:**
- `lib/features/repos/data/models/commit_detail_model.dart`
- `lib/features/repos/domain/entities/commit_detail_entity.dart`
- `lib/features/repos/presentation/screens/commit_detail_screen.dart`

---

### S2-3 · Repos infinite scroll / pagination
**Why:** `getRepos()` fetches a fixed page. Users with 200+ repos only see the
first batch. The repos list needs proper pagination matching the commits/PRs/issues pattern.

**Scope:**
- Create `reposNotifierProvider` (StateNotifierProvider) mirroring `commitsNotifierProvider`
- State: `{ repos, isLoading, isLoadingMore, hasMore, error }`
- `loadMore()` fetches next page and appends
- Scroll listener in `ReposScreen` triggers `loadMore()` at maxScrollExtent - 300
- `allReposProvider` for GitLab repos stays as FutureProvider (GitLab has fewer repos)
- The merged list (GitHub paginated + GitLab) needs careful ordering

**Files:**
- `lib/features/repos/presentation/providers/repos_provider.dart`
- `lib/features/repos/presentation/screens/repos_screen.dart`
- `lib/features/repos/data/datasources/github_remote_datasource.dart` (add page param)

---

### S2-4 · File browser branch selector
**Why:** File browser always shows the default branch. Developers frequently
need to browse a feature branch or a release tag.

**Scope:**
- Add branch dropdown to `RepoBrowserScreen` AppBar (reuse branches from `repoBranchesProvider`)
- Pass selected branch as query param to `getContents()`
- Breadcrumb navigation resets to root on branch change

**Files:**
- `lib/features/repos/presentation/screens/repo_browser_screen.dart`
- `lib/features/repos/data/datasources/github_remote_datasource.dart` (add ref param to getContents)

---

## Sprint 3 — Polish

### S3-1 · App icon (all platforms)
**Why:** Default Flutter icon looks unprofessional. Every platform needs a
properly sized custom icon.

**Scope:**
- Design icon (hub/sphere concept matching the splash screen)
- Use `flutter_launcher_icons` package
- Generate icons for: iOS, Android, macOS, Windows, Linux, Web (favicon + 192/512)
- Update `pubspec.yaml` with `flutter_icons` config

**Files:**
- `pubspec.yaml`
- `assets/icon/` (new icon assets)
- All platform `**/Runner/Assets.xcassets/` etc. (auto-generated)

---

### S3-2 · Keyboard navigation
**Why:** Web and desktop users expect Tab key navigation, arrow key list
traversal, and Escape to close dialogs/sheets. Currently only `/` works.

**Scope:**
- `Escape` key closes open dialogs, bottom sheets, and navigates back
- `Tab` / `Shift+Tab` traverses focusable elements correctly
- `Enter` opens the focused repo card
- `R` triggers refresh on the current screen
- `?` opens a keyboard shortcuts help dialog
- Register handlers in each screen's `initState` via `HardwareKeyboard`

**Files:**
- `lib/features/repos/presentation/screens/repos_screen.dart`
- `lib/features/repos/presentation/screens/repo_detail_screen.dart`
- (shared shortcut handler helper if pattern repeats)

---

### S3-3 · User-friendly error messages
**Why:** Raw exception strings like `"Exception: Request failed with status 422"`
reach the UI through `ErrorView` and `.when(error: ...)` handlers.

**Scope:**
- Strip `"Exception: "` prefix (already partially done in `create_issue_sheet.dart`)
- Map known exception types to human-readable messages in `ErrorView`
- Add specific copy for: no internet, rate limit, auth expired, not found
- `ErrorView` should show different icons per error type

**Files:**
- `lib/shared/widgets/error_view.dart`
- All `.when(error: (e, _) => ...)` call sites

---

### S3-4 · Web meta tags + PWA manifest
**Why:** RepoSphere is web-first. Without proper meta tags, sharing a link
shows no preview. Without a manifest, it can't be installed as a PWA.

**Scope:**
- `web/index.html`: add `<meta name="description">`, Open Graph tags,
  `<link rel="manifest">`, theme-color, apple-touch-icon
- `web/manifest.json`: name, short_name, icons, start_url, display: standalone,
  theme_color, background_color
- `web/favicon.png`: replace Flutter default

**Files:**
- `web/index.html`
- `web/manifest.json`
- `web/favicon.png` / `web/icons/`

---

## Sprint 4 — Scale

### S4-1 · Unit + widget tests
**Why:** Zero test coverage means regressions go undetected. Minimum viable
test suite before any public launch.

**Priority targets:**
```
Unit:
  - GitHubRemoteDatasource: mock http.Client, assert correct URLs + headers
  - RepoModel.fromJson / GitLabProjectModel.fromJson: golden JSON fixtures
  - PinnedReposNotifier: toggle, load, persist
  - filteredReposProvider: filter + sort + search logic

Widget:
  - RepoCard: renders correctly, hover state, copy button
  - ErrorView: shows message + retry button
  - CreateIssueSheet: form validation, submit flow
```

**Files:**
- `test/` directory (currently empty or missing)

---

### S4-2 · GitHub Actions CI pipeline
**Why:** No automated checks on PRs. Regressions merged silently.

**Scope:**
```yaml
# .github/workflows/ci.yml
on: [push, pull_request]
jobs:
  analyze:   dart analyze lib/
  test:      flutter test
  build-web: flutter build web --release
```

**Files:**
- `.github/workflows/ci.yml` (new)

---

### S4-3 · Crash reporting (Sentry)
**Why:** No visibility into what breaks in production for real users.

**Scope:**
- Add `sentry_flutter` package
- Wrap `runApp` in `SentryFlutter.init()`
- DSN stored in `AppConfig` (env var for web, build arg for native)
- Custom user context: `Sentry.configureScope(scope => scope.setUser(...))`

**Files:**
- `pubspec.yaml`
- `lib/main.dart`
- `lib/core/config/app_config.dart`

---

### S4-4 · Internationalization (i18n)
**Why:** All strings are hardcoded in English. Required for global reach.

**Scope:**
- Add `flutter_localizations` + `intl` packages
- Extract all user-visible strings to ARB files (`lib/l10n/app_en.arb`)
- Support: English (default), Arabic (RTL — the team already works in Arabic)
- RTL layout support via `Directionality` widget

**Files:**
- `pubspec.yaml`
- `lib/l10n/` (new)
- All screen/widget files (string extraction)

---

## Status Summary

| ID    | Item                          | Sprint | Status |
|-------|-------------------------------|--------|--------|
| S1-1  | Settings + GitLab UI          | 1      | [ ]    |
| S1-2  | `_checkResponse` all codes    | 1      | [ ]    |
| S1-3  | Token expiry → auto logout    | 1      | [ ]    |
| S2-1  | Notifications badge           | 2      | [ ]    |
| S2-2  | Commit diff view              | 2      | [ ]    |
| S2-3  | Repos pagination              | 2      | [ ]    |
| S2-4  | File browser branch selector  | 2      | [ ]    |
| S3-1  | App icon all platforms        | 3      | [ ]    |
| S3-2  | Keyboard navigation           | 3      | [ ]    |
| S3-3  | User-friendly errors          | 3      | [ ]    |
| S3-4  | Web meta tags + PWA manifest  | 3      | [ ]    |
| S4-1  | Unit + widget tests           | 4      | [ ]    |
| S4-2  | GitHub Actions CI             | 4      | [ ]    |
| S4-3  | Crash reporting (Sentry)      | 4      | [ ]    |
| S4-4  | i18n / Arabic RTL             | 4      | [ ]    |
