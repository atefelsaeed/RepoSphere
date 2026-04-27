# RepoSphere — Improvements Backlog
> Last updated: April 2026

Tracked items needed to bring RepoSphere to a world-class, shippable standard.
Each item has a status tag: `[ ]` pending · `[x]` done · `[-]` skipped/deferred.

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
