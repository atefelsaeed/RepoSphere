# RepoSphere — Product & Architecture Spec
> Version 4.0 | Last updated: April 2026

---

## 1. Vision

RepoSphere is not a GitHub clone.

It is a **unified developer control center** — one place where any developer working across multiple Git providers, organizations, and projects can see, manage, and act on everything without switching tabs.

> "Your entire Git universe, one dashboard."

---

## 2. Target Users

| User | Pain |
|---|---|
| Freelancer | Works on 5+ client repos across different orgs |
| Open source contributor | Contributes to repos they don't own |
| Agency developer | Manages projects across GitHub + GitLab |
| Tech lead | Monitors team activity across multiple repos |
| Solo SaaS founder | Needs a quick view of all their projects |

---

## 3. Platform Strategy

**Primary:** Flutter (Web first, then Desktop, then Mobile)

### Why Flutter

- One codebase → Web + macOS + Windows + Linux + iOS + Android
- Critical for a small team — no duplicated effort
- Flutter Web has matured enough for SaaS dashboards
- Desktop app = power user retention

### Deployment Targets

```
Web        → Primary (SaaS, browser-accessible)
macOS      → Power users, native feel
Windows    → Enterprise & agency developers
Mobile     → Monitoring on the go (view only in MVP)
```

---

## 4. Design System

### 4.1 Brand Identity

RepoSphere is **not** a GitHub UI copy. It has its own visual identity:
bold, modern, dark-first, developer-focused with a premium feel.

### 4.2 Color Palette

```
Brand:            #4F46E5 (Indigo) / #818CF8 (Indigo Light)

── Dark Theme ──────────────────────────────
Background:       #070B14
Surface:          #0D1321
Card:             #111827
Border:           #1F2937
Text Primary:     #F9FAFB
Text Muted:       #6B7280

── Light Theme ─────────────────────────────
Background:       #F8FAFC
Surface:          #FFFFFF
Card:             #FFFFFF
Border:           #E2E8F0
Text Primary:     #0F172A
Text Muted:       #64748B

── Semantic Colors ──────────────────────────
Open / Success:   #3FB950   (green)
Merged:           #A371F7   (purple)
Closed / Error:   #EF4444   (red)
Draft / Muted:    #6B7280   (gray)
Warning:          #F59E0B   (amber)
File / Branch:    #54AEFF   (blue)
GitLab:           #FC6D26   (orange)
```

### 4.3 Typography

```
UI Font:    Inter       (via google_fonts — applied globally)
Code Font:  monospace   (system monospace for SHAs, diffs, code)
```

### 4.4 Spacing & Shape

```
Border Radius:
  Cards:      12px
  Chips/Tags: 20px (pill)
  Buttons:    10px
  Inputs:     8-10px

Elevation:
  Cards use colored border — no Material elevation
  Hover state: indigo glow via BoxShadow with low opacity
  Nav buttons: per-accent glow (green, amber, purple, etc.)
```

### 4.5 Motion System (fully implemented)

```
Packages:  flutter_animate, shimmer

Loading states    → ShimmerBox / ShimmerRepoCard / ShimmerListTile
                   (no CircularProgressIndicator anywhere in the app)

List entrances    → staggered fadeIn + slideY/slideX
                   delay: index × 30-40ms, capped at 300-400ms

Filter chips      → AnimatedScale with Curves.elasticOut (spring bounce)
Page sections     → fadeIn + slideY(begin: 0.06) on entry
Empty states      → fadeIn(duration: 300ms)

Hover effects     → AnimatedContainer, 150-160ms, Curves.easeOut
  Repo cards:       border → primary color, indigo glow shadow
  Nav buttons:      border → accent color, per-button glow shadow
  Theme toggle:     instant icon swap (system/light/dark)

Copy micro-animation → AnimatedSwitcher: link icon → green checkmark (2s)
Pin micro-animation  → AnimatedSwitcher: outlined pin → filled primary pin

Durations:
  Micro:    150-160ms (hover transitions, copy feedback)
  Standard: 250-300ms (list items, section entrances)
  Slow:     350ms     (page-level content fade)
```

### 4.6 Splash Screen

```
Animated launch screen in app.dart:
  Hub icon  → elastic scale (Curves.elasticOut, 600ms)
  "RepoSphere" text → fadeIn + slideY (delay 200ms)
  Tagline   → fadeIn (delay 400ms)
No native splash; purely Flutter-rendered for consistency.
```

---

## 5. Architecture

### 5.1 Project Structure

```
lib/
├── core/
│   ├── router/           GoRouter + _RouterNotifier (auth redirect)
│   │                     18 named routes + 404 errorBuilder
│   ├── theme/            AppTheme — dark + light ThemeData, AppColors
│   ├── providers/        themeModeProvider, supabaseClientProvider
│   ├── constants/        AppConstants (API base), kLanguageColors map
│   ├── config/           AppConfig (OAuth + Supabase credentials)
│   └── utils/            GitHubAuthException, GitHubRateLimitException
│
├── features/
│   ├── auth/
│   │   ├── data/         SecureTokenStorage (flutter_secure_storage)
│   │   │                 GitHubDeviceAuth (Device Flow + polling)
│   │   │                 SupabaseAuthService (OAuth via Supabase)
│   │   └── presentation/ AuthScreen (three-tier) + AuthNotifier
│   │
│   └── repos/
│       ├── domain/
│       │   ├── entities/ RepoEntity (+ RepoProvider enum),
│       │   │             UserEntity, CommitEntity,
│       │   │             CommitDetailEntity, BranchEntity,
│       │   │             PullRequestEntity, IssueEntity,
│       │   │             IssueCommentEntity, RepoContentItem,
│       │   │             FileContent, ActivityEventEntity,
│       │   │             ContributorEntity, NotificationEntity,
│       │   │             ReleaseEntity, GistEntity
│       │   └── repos/    GitProvider (abstract interface)
│       │
│       ├── data/
│       │   ├── models/   RepoModel, UserModel, CommitModel,
│       │   │             CommitDetailModel, BranchModel,
│       │   │             PullRequestModel, IssueModel,
│       │   │             IssueCommentModel, ContributorModel,
│       │   │             ActivityEventModel, NotificationModel,
│       │   │             ReleaseModel, GistModel,
│       │   │             GitLabProjectModel
│       │   ├── datasources/  GitHubRemoteDatasource (25 API methods)
│       │   │                 GitLabRemoteDatasource (projects, starred)
│       │   └── repositories/ GitHubRepoRepositoryImpl
│       │
│       └── presentation/
│           ├── screens/  ReposScreen, RepoDetailScreen,
│           │             RepoBrowserScreen, FileViewerScreen,
│           │             RepoCommitsScreen, CommitDetailScreen,
│           │             RepoPrsScreen, RepoPrDetailScreen,
│           │             RepoIssuesScreen, RepoIssueDetailScreen,
│           │             RepoReadmeScreen, RepoReleasesScreen,
│           │             ActivityScreen, NotificationsScreen,
│           │             GistsScreen, SearchScreen, ProfileScreen
│           │
│           ├── providers/ repos_provider (filter, sort, search,
│           │             gitlab merge), pinned_repos_provider,
│           │             commits_notifier (paginated),
│           │             commit_detail_provider,
│           │             repo_branches_provider,
│           │             repo_commits_provider,
│           │             repo_prs_provider (paginated),
│           │             repo_issues_provider (paginated),
│           │             repo_readme_provider,
│           │             repo_contents_provider,
│           │             repo_languages_provider,
│           │             repo_contributors_provider,
│           │             repo_releases_provider,
│           │             is_starred_provider,
│           │             activity_provider,
│           │             notifications_provider,
│           │             issue_comments_provider,
│           │             gists_provider,
│           │             global_search_provider,
│           │             recent_searches_provider
│           │
│           └── widgets/  RepoCard (ConsumerStatefulWidget,
│                         pin indicator + GL badge),
│                         CommitTile, LabelChip,
│                         CommentThread + CommentCard,
│                         CreateIssueSheet
│
├── shared/
│   └── widgets/          ErrorView, ShimmerBox, ShimmerRepoCard,
│                         ShimmerListTile
│
├── app.dart              RepoSphereApp + _SplashScreen (animated)
└── main.dart             Supabase.initialize() (guarded by AppConfig)
```

### 5.2 Provider Abstraction

```dart
abstract class GitProvider {
  Future<UserEntity> getUser();
  Future<List<RepoEntity>> getRepos();
  Future<List<RepoEntity>> getStarredRepos();
}

// Implementations:
// ✅ GitHubRepoRepositoryImpl
// ✅ GitLabRemoteDatasource  (direct datasource — merged in allReposProvider)
// 🔜 BitbucketRepoRepositoryImpl (Phase 4)
```

### 5.3 State Management (Riverpod 2.x)

```
Core:
  authProvider              AsyncNotifier<String?>
  githubDatasourceProvider  Provider<GitHubRemoteDatasource?>
  gitlabDatasourceProvider  FutureProvider<GitLabRemoteDatasource?>
  gitProviderProvider       Provider<GitProvider?>
  supabaseClientProvider    Provider<SupabaseClient?>
  themeModeProvider         StateProvider<ThemeMode>

User & Repos:
  currentUserProvider       FutureProvider<UserEntity?>
  allReposProvider          FutureProvider<List<RepoEntity>>   ← GitHub + GitLab merged
  starredReposProvider      FutureProvider<List<RepoEntity>>
  gitlabReposProvider       FutureProvider<List<RepoEntity>>
  filteredReposProvider     Provider<AsyncValue<List<RepoEntity>>>
  repoFilterProvider        StateProvider<RepoFilter>
  searchQueryProvider       StateProvider<String>
  repoSortProvider          StateProvider<RepoSort>
  pinnedReposProvider       StateNotifierProvider<Set<int>>    ← persisted SharedPreferences

Discovery:
  globalSearchProvider      FutureProvider.family<List<RepoEntity>, String>
  recentSearchesProvider    StateNotifierProvider<List<String>>

Feature Providers (family):
  repoBranchesProvider      FutureProvider.family (owner, repo)
  repoCommitsProvider       FutureProvider.family (owner, repo)  [detail screen]
  commitsNotifierProvider   StateNotifierProvider.family         [paginated commits]
  commitDetailProvider      FutureProvider.family (owner, repo, sha)
  repoPrsProvider           StateNotifierProvider.family         [paginated PRs]
  repoIssuesProvider        StateNotifierProvider.family         [paginated issues]
  repoReadmeProvider        FutureProvider.family (owner, repo)
  repoContentsProvider      FutureProvider.family (owner, repo, path)
  fileContentProvider       FutureProvider.family (owner, repo, path)
  repoLanguagesProvider     FutureProvider.family (owner, repo)
  repoContributorsProvider  FutureProvider.family (owner, repo)
  repoReleasesProvider      FutureProvider.family (owner, repo)
  isStarredProvider         FutureProvider.family (owner, repo)
  issueCommentsProvider     FutureProvider.family (owner, repo, number)

Global Feed:
  activityProvider          FutureProvider<List<ActivityEventEntity>>
  notificationsProvider     StateNotifierProvider<List<NotificationEntity>>
  gistsProvider             FutureProvider<List<GistEntity>>
```

### 5.4 Pagination Pattern

Commits, PRs, and Issues all use the same `StateNotifier` pagination pattern:

```dart
// State holds: items list, isLoading, isLoadingMore, hasMore, error, filter
// Notifier exposes: loadMore(), refresh(), changeBranch/changeFilter()
// UI: scroll listener triggers loadMore() at maxScrollExtent - 300px
//     "load more" slot at end of list shows ShimmerListTile while loading
```

### 5.5 Router — Named Routes (18 total)

```
/auth                         AuthScreen
/repos                        ReposScreen            [shell root]
  :id                         RepoDetailScreen
  :id/browse/*path            RepoBrowserScreen
  :id/commits                 RepoCommitsScreen
  :id/commits/:sha            CommitDetailScreen
  :id/prs                     RepoPrsScreen
  :id/prs/:number             RepoPrDetailScreen
  :id/issues                  RepoIssuesScreen
  :id/issues/:number          RepoIssueDetailScreen
  :id/readme                  RepoReadmeScreen
  :id/releases                RepoReleasesScreen
  :id/files/*path             FileViewerScreen
/profile                      ProfileScreen
/search                       SearchScreen
/activity                     ActivityScreen
/notifications                NotificationsScreen
/gists                        GistsScreen
[errorBuilder]                404 page (icon + route label + Go home)
```

### 5.6 Three-Tier Auth System

```
Priority order (highest → lowest):

1. Supabase OAuth   — if AppConfig.hasSupabase
   SupabaseAuthService.signInWithGitHub() → web OAuth redirect
   providerToken extracted from Supabase session on return
   AuthNotifier subscribes to onAuthStateChange stream

2. GitHub Device Flow — if AppConfig.hasGitHubOAuth
   POST /login/device/code → device_code + user_code
   Dialog: monospace XXXX-YYYY code + "Open github.com/login/device"
   Poll /login/oauth/access_token every N seconds until approved

3. PAT fallback — always available
   TextField → validate via GET /user → store in SecureStorage
```

### 5.7 Architecture Evolution by Phase

```
Phase 1 (MVP — ✅ complete):
  Flutter App ──► GitHub REST API v3
                  Local SecureStorage (PAT token)
                  SharedPreferences (theme, recent searches, pinned repos)

Phase 2 (Auth — ✅ complete):
  Flutter App ──► GitHub OAuth Device Flow (no backend required)
              ──► Supabase Auth (optional — web OAuth)
              ──► GitLab PAT (read repos, merged into dashboard)

Phase 3 (Scale):
  Flutter App ──► API Gateway
              ──► Provider Service  (GitHub, GitLab, Bitbucket)
              ──► Notification Service (webhooks → push)
              ──► Cache Layer (Redis)
              ──► Analytics Service
```

---

## 6. Feature Status

### Phase 1 — MVP ✅ Complete

#### Core Infrastructure
```
✅ Clean architecture (domain / data / presentation)
✅ GoRouter with auth-based redirect guard (18 named routes + 404 page)
✅ GitHub PAT token auth (secure storage)
✅ Dark + Light + System theme with toggle in AppBar
✅ Theme mode persisted via shared_preferences
✅ Animated splash screen (hub icon elastic scale + staggered text)
✅ Error views with retry across all screens
✅ Responsive grid (1→2→3→4 columns based on width)
✅ No CircularProgressIndicator anywhere — shimmer-only loading
✅ / keyboard shortcut → focus inline search bar on ReposScreen
```

#### Repos List Screen
```
✅ All repos (owner + collaborator + org member) — GitHub + GitLab merged
✅ Starred repos tab
✅ Filter chips: All / Owned / Forked / Starred / Public / Private
✅ Sort dropdown: Last Updated / Stars / Name / Created
✅ Live search (name + description + language)
✅ Animated repo count badge
✅ Shimmer skeleton grid on load
✅ Staggered card entrance animations
✅ Pull-to-refresh
✅ Pinned repos section — horizontal chip row, shown when filter=All
      and no active search query and at least one repo is pinned
```

#### Repo Card
```
✅ Owner avatar + full name
✅ Private badge
✅ GitLab badge (orange "GL" chip for GitLab repos)
✅ Pin indicator (push_pin icon when pinned)
✅ Language dot + name
✅ Fork indicator
✅ Star count
✅ Last updated (timeago)
✅ Copy link button with AnimatedSwitcher → green checkmark (2s)
✅ Open on GitHub/GitLab button
✅ Hover lift effect (border + glow shadow)
✅ Spring filter chip animation on select
```

#### Repo Detail Screen
```
✅ Owner avatar + name + repo name
✅ Public / Private chip
✅ Description
✅ Stats row: Stars / Forks / Watchers / Open Issues
✅ Pin / Unpin toggle in AppBar (AnimatedSwitcher: outlined ↔ filled primary)
✅ Star / Unstar toggle button in AppBar (live state via isStarredProvider)
✅ Copy link button with checkmark micro-animation in AppBar
✅ Quick nav buttons: PRs / Issues / README / Commits / Browse / Releases
      → Each button has per-accent hover glow
✅ Language bar: segmented colored bar + percentage legend
✅ Contributors row: avatar strip with commit-count tooltip (top 10)
✅ Clone section: HTTPS + SSH with per-row copy→checkmark
✅ Language + Fork + Branch info chips
✅ Topics
✅ Created / Last updated dates
✅ Recent commits section (3 commits with shimmer on load)
✅ "View all" → in-app commits screen
✅ Open on GitHub in AppBar
✅ Browse Code button
```

#### File Browser
```
✅ Directory listing (files + folders, sorted dirs-first)
✅ Breadcrumb navigation (clickable path segments)
✅ File type icons by extension
✅ File size display
✅ Shimmer skeleton on load (14 tiles)
✅ Staggered slide-up animation on load
✅ Empty directory state
```

#### File Viewer
```
✅ Syntax highlighting via flutter_highlight
✅ Line numbers column
✅ Language auto-detection (20+ extensions)
✅ Horizontal scroll for wide code
✅ Binary file detection
✅ Copy file content button
✅ Open on GitHub button
✅ Light/dark syntax themes (atom-one)
```

#### Commits Screen
```
✅ Full paginated commit list
✅ Branch selector dropdown in AppBar
      → Fetches all branches, marks default with badge
✅ Author avatar + login
✅ Commit message (first line)
✅ Timeago date
✅ Short SHA chip (tap to copy full SHA)
✅ Tap commit → in-app Commit Detail screen
✅ Shimmer skeleton on initial load
✅ Shimmer on "load more" slot
✅ Staggered slide animation on load
✅ Pull-to-refresh
✅ Empty branch state
```

#### Commit Detail Screen
```
✅ Full commit message (title + body)
✅ Author avatar + login + timeago
✅ Stats bar: files changed, +additions, -deletions
✅ Per-file list:
      → Status badge (A=added, M=modified, D=deleted, R=renamed)
      → Full file path
      → Per-file +/- counts (color coded)
✅ Shimmer skeleton on load
✅ Staggered file list animation
✅ Open on GitHub button
```

#### Pull Requests Screen
```
✅ Paginated PR list
✅ Tabs: Open / Closed / Merged
✅ State icon + color per PR
✅ Title, #number, head→base branch
✅ Author avatar + login
✅ Labels (colored chips)
✅ Comment count
✅ Timeago
✅ Tap → in-app PR Detail screen
✅ Shimmer skeleton on load
✅ Staggered animation
✅ Pull-to-refresh
```

#### PR Detail Screen
```
✅ Title + state badge (colored pill: Open/Merged/Closed/Draft)
✅ Author avatar + opened timeago
✅ head → base branch info box
✅ Labels row
✅ Full PR body rendered in Markdown
✅ "No description" fallback
✅ Inline comments thread (CommentThread widget)
      → Author avatar + login + timeago
      → Markdown body per comment
      → Open comment on GitHub link
      → Shimmer skeleton while loading
✅ Open on GitHub in AppBar
✅ Staggered section animations
```

#### Issues Screen
```
✅ Paginated issue list
✅ Tabs: Open / Closed
✅ State icon (circle open / check closed)
✅ Title, #number, opened/closed timeago
✅ Author login
✅ Labels (colored chips)
✅ Comment count
✅ Tap → in-app Issue Detail screen
✅ Create Issue FAB (GitHub repos only) → bottom sheet form
✅ Shimmer skeleton on load
✅ Staggered animation
✅ Pull-to-refresh
```

#### Issue Detail Screen
```
✅ Title + state badge (green open / purple closed)
✅ Author avatar + opened/closed timeago
✅ Labels row
✅ Full issue body rendered in Markdown
✅ "No description" fallback
✅ Inline comments thread (shared CommentThread widget)
      → Avatar, login, timeago, open-on-GitHub link
      → Markdown body per comment
      → Shimmer skeleton while loading
✅ Open on GitHub in AppBar
✅ Staggered section animations
```

#### Create Issue Sheet
```
✅ Modal bottom sheet (GitHub repos only)
✅ Title field (required, validated)
✅ Description field (multiline, optional)
✅ Loading state (CircularProgressIndicator inside button)
✅ Error banner on failure
✅ On success: dismisses sheet + triggers issues list refresh
```

#### README Screen
```
✅ Full Markdown rendering (flutter_markdown_plus)
✅ Selectable text
✅ Code blocks with theme background
✅ Blockquote styling
✅ External links open in browser
✅ Rich shimmer skeleton (title + text lines + code block)
✅ Empty state (no README found)
✅ Fade-in on content load
```

#### Releases Screen
```
✅ Paginated release list per repo
✅ Tag chip (monospace)
✅ Badge: Latest (first stable only) / Pre-release / Draft
✅ Author avatar + login
✅ Full release notes rendered in Markdown
✅ Timeago
✅ Open on GitHub button per release
✅ Shimmer skeleton on load
✅ Staggered slide animation
✅ Empty state (no releases)
```

#### Activity Screen
```
✅ User's recent GitHub events feed
✅ Per-event icon + accent color (PushEvent, PullRequestEvent,
      IssuesEvent, WatchEvent, ForkEvent, CreateEvent, etc.)
✅ Actor avatar + summary text
✅ Repo name with icon
✅ Timeago
✅ Tap → open event on GitHub
✅ Pull-to-refresh
✅ Shimmer skeleton on load (no spinner — shimmer only)
✅ Staggered animation
✅ Empty state
```

#### Notifications Screen
```
✅ Unread GitHub notifications list
✅ Unread blue dot indicator
✅ Per-type icon (PullRequest, Issue, Commit, Release, etc.)
✅ Reason label (mention, review_requested, subscribed, etc.)
✅ Repo name
✅ Timeago
✅ Tap to open on GitHub → auto-marks as read
✅ "Mark all read" AppBar action button
✅ Shimmer skeleton on load
✅ Staggered animation
✅ Empty state (all caught up)
```

#### Gists Screen
```
✅ Authenticated user's gists list
✅ /gists named route in GoRouter
✅ Public / Secret badge
✅ File chips: name + language (up to 5 per gist)
✅ Updated timeago
✅ Comment count
✅ Tap → open gist on GitHub
✅ Pull-to-refresh
✅ Shimmer skeleton on load
✅ Staggered animation
✅ Empty state
```

#### Search Screen
```
✅ Global GitHub repository search (REST search API)
✅ 500ms debounce on input
✅ Recent searches history (persisted via shared_preferences, max 10)
      → Shown as list when no query is active
      → Per-item remove button
      → "Clear all" action
✅ Auto-saves query on successful results
✅ Results count header
✅ RepoCard list with staggered animation
✅ Shimmer skeleton while loading
✅ Empty state (no results for query)
✅ Error state with message
```

#### Profile Screen
```
✅ Large avatar (96px radius)
✅ Name + @login
✅ Bio
✅ Info rows: location, company, email (mailto), blog (opens browser)
✅ Joined date (timeago)
✅ Stats: Repos / Followers / Following
✅ Shimmer skeleton on load
✅ Staggered info row animations
✅ Pull-to-refresh
✅ ErrorView on failure
✅ Gists shortcut in AppBar
✅ Accessible via avatar tap in repos AppBar
```

---

### Phase 2 — Auth Evolution ✅ Complete

#### GitHub OAuth Device Flow
```
✅ AppConfig.githubClientId — fill in to enable Device Flow
✅ GitHubDeviceAuth: POST /login/device/code → poll for token
✅ Dialog: verification URL button + large monospace XXXX-YYYY code
✅ Copy-on-tap for user code
✅ Polling spinner with cancel button
✅ Handles: authorization_pending, slow_down, expired_token, access_denied
✅ PAT fallback always available ("Use a token instead")
```

#### Supabase Auth (optional backend)
```
✅ AppConfig.supabaseUrl + supabaseAnonKey — fill in to enable
✅ SupabaseAuthService.signInWithGitHub() → web OAuth redirect
✅ AuthNotifier subscribes to onAuthStateChange stream
✅ providerToken (GitHub OAuth token) extracted from Supabase session
✅ Logout: calls supabase.auth.signOut() when configured
✅ Supabase.initialize() guarded by AppConfig.hasSupabase in main.dart
```

#### Auth Priority
```
Priority (highest → lowest):
  1. Supabase OAuth    — if AppConfig.hasSupabase
  2. Device Flow       — elif AppConfig.hasGitHubOAuth
  3. PAT entry form    — always
```

#### GitLab Integration
```
✅ GitLabRemoteDatasource — Bearer token, /api/v4/projects
✅ GitLabProjectModel → toEntity() with RepoProvider.gitlab
✅ gitlabDatasourceProvider — reads token from SecureStorage (opt-in)
✅ gitlabReposProvider — maps projects to RepoEntity list
✅ allReposProvider — merges GitHub + GitLab repos
✅ RepoProvider enum on RepoEntity (github | gitlab)
✅ Orange "GL" badge on repo cards for GitLab repos
✅ Create Issue FAB hidden for GitLab repos (GitHub-only action)
```

#### Repo Pinning
```
✅ pinnedReposProvider — StateNotifierProvider<Set<int>>
✅ Persisted via SharedPreferences (pinned_repo_ids)
✅ toggle(repoId) — adds/removes + auto-saves
✅ Pin indicator (push_pin icon) on repo cards
✅ Pin/Unpin toggle in repo detail AppBar (AnimatedSwitcher)
✅ Pinned section on repos screen — horizontal scrollable chip row
      Visible only when: filter=All AND search empty AND ≥1 pinned
```

---

### Phase 3 — Power Features `[Next]`

```
Repo Management:
  ⬜ PR Review (view diff, approve, request changes, comment)
  ⬜ Issue management: assign, label, close/reopen
  ⬜ Comment on issues and PRs
  ⬜ Custom collections (group repos by project/client)
  ⬜ Code diff viewer (compare branches/commits)

Multi-Provider:
  ⬜ GitLab commits, MRs, issues (in-app screens)
  ⬜ GitLab OAuth (replace PAT)
  ⬜ Bitbucket repos + PRs

Productivity:
  ⬜ Cross-repo notifications (webhook-driven)
  ⬜ Mobile push notifications
  ⬜ Keyboard navigation (arrow keys for lists)
```

### Phase 4 — Monetization & Scale

```
Subscriptions (Stripe):
  ┌─────────────────────────────────────────┐
  │  FREE                                    │
  │  · 1 provider                           │
  │  · 20 repos visible                     │
  │  · Commits + file browser               │
  ├─────────────────────────────────────────┤
  │  PRO — $9/month                         │
  │  · All providers (GitHub + GitLab + BB) │
  │  · Unlimited repos                      │
  │  · PRs + Issues management              │
  │  · Notifications + activity feed        │
  ├─────────────────────────────────────────┤
  │  TEAM — $25/month per team              │
  │  · Everything in Pro                    │
  │  · Shared team workspace                │
  │  · Team activity feed                   │
  │  · Analytics dashboard                  │
  └─────────────────────────────────────────┘

Tech:
  ⬜ Stripe integration
  ⬜ Usage limits per tier
  ⬜ Upgrade prompts at boundaries
  ⬜ Admin dashboard
  ⬜ Billing history screen
```

---

## 7. GitHub API Coverage

```
── User ──────────────────────────────────────────────────────────────
✅ GET  /user                                    Current user profile
✅ GET  /user/repos                              All repos
✅ GET  /user/starred                            Starred repos
✅ GET  /user/starred/{owner}/{repo}             Is repo starred? (204/404)
✅ PUT  /user/starred/{owner}/{repo}             Star a repo
✅ DELETE /user/starred/{owner}/{repo}           Unstar a repo
✅ GET  /users/{username}/events                 Activity feed

── Repos ─────────────────────────────────────────────────────────────
✅ GET  /repos/{owner}/{repo}/branches           Branch list
✅ GET  /repos/{owner}/{repo}/commits            Paginated commits
✅ GET  /repos/{owner}/{repo}/commits/{sha}      Commit detail + files
✅ GET  /repos/{owner}/{repo}/pulls              Paginated PRs
✅ GET  /repos/{owner}/{repo}/issues             Paginated issues (PRs filtered out)
✅ POST /repos/{owner}/{repo}/issues             Create issue
✅ GET  /repos/{owner}/{repo}/issues/{n}/comments  Issue/PR comments
✅ GET  /repos/{owner}/{repo}/readme             README (base64 decoded)
✅ GET  /repos/{owner}/{repo}/contents/{path}    File browser + content
✅ GET  /repos/{owner}/{repo}/languages          Language bytes map
✅ GET  /repos/{owner}/{repo}/contributors       Contributor list
✅ GET  /repos/{owner}/{repo}/releases           Releases list

── Search ────────────────────────────────────────────────────────────
✅ GET  /search/repositories                     Global repo search

── Notifications ─────────────────────────────────────────────────────
✅ GET  /notifications                           Unread notifications
✅ PATCH /notifications/threads/{id}             Mark thread as read
✅ PUT  /notifications                           Mark all as read

── Gists ─────────────────────────────────────────────────────────────
✅ GET  /gists                                   Authenticated user's gists

── Planned ───────────────────────────────────────────────────────────
⬜ POST /repos/{owner}/{repo}/issues/{n}/comments  Comment on issue
⬜ PATCH /repos/{owner}/{repo}/issues/{n}         Update issue (close/assign)
⬜ POST /repos/{owner}/{repo}/pulls/{n}/reviews  Review PR
⬜ GET  /repos/{owner}/{repo}/compare/{b}...{h}  Diff view
```

## 8. GitLab API Coverage

```
── Projects ──────────────────────────────────────────────────────────
✅ GET  /api/v4/projects                         User's projects (membership)
✅ GET  /api/v4/projects?starred=true            Starred projects

── Planned ───────────────────────────────────────────────────────────
⬜ GET  /api/v4/projects/{id}/repository/commits  Commits
⬜ GET  /api/v4/projects/{id}/merge_requests      Merge Requests
⬜ GET  /api/v4/projects/{id}/issues              Issues
```

---

## 9. Tech Stack

```
Frontend:
  Framework:        Flutter 3.x (multi-platform)
  State:            Riverpod 2.x (Provider, FutureProvider.family,
                                  StateNotifierProvider.family,
                                  StateProvider, AsyncNotifier)
  Navigation:       GoRouter 14.x (named routes, auth redirect, 404 page)
  HTTP:             http (→ dio in Phase 3 for interceptors + retry)
  Auth storage:     flutter_secure_storage (Keychain / EncryptedSharedPrefs)
  Persistence:      shared_preferences (theme, recent searches, pinned repos)
  Animations:       flutter_animate (stagger, fade, slide, scale, elastic)
  Loading:          shimmer (ShimmerBox, ShimmerRepoCard, ShimmerListTile)
  Markdown:         flutter_markdown_plus
  Code highlight:   flutter_highlight (atom-one dark/light)
  Open URLs:        url_launcher
  Time display:     timeago
  Font:             google_fonts (Inter)

Auth (optional — fill AppConfig to enable):
  OAuth Device Flow: github.com/login/device (no backend needed)
  Supabase:          supabase_flutter — web OAuth + session management

Backend (Phase 3+):
  Auth + DB:        Supabase
  Payments:         Stripe
  Hosting (web):    Vercel / Cloudflare Pages
  API proxy:        Supabase Edge Functions

CI/CD:
  Source control:   GitHub
  Build & deploy:   GitHub Actions
  Web deploy:       Vercel (auto on push to main)
```

---

## 10. UX Principles

```
1. Zero friction
   Value within 60 seconds. Connect token → see repos immediately.
   No long onboarding flows.

2. Information hierarchy
   Repo name, language, last updated visible without any clicks.
   Stars, forks, issues on card. Details on demand.

3. Dark first
   Developers live in dark mode. Light is the alternative.
   Toggle: System → Light → Dark → System (persisted via SharedPreferences).

4. Speed perception
   No blank states. Shimmer skeletons appear instantly.
   Staggered list animations give a sense of progressive loading.

5. Keyboard friendly
   / to focus search (implemented).
   Arrow keys to navigate lists (planned).

6. Responsive by default
   4-column grid ≥1200px → 3 ≥900px → 2 ≥600px → 1 on mobile.
   Every screen works at 375px and 1440px.

7. In-app everything
   No links that kick users to GitHub for content we can show.
   PRs, Issues, Commits, READMEs, Files, Releases — all in-app.
   Comments rendered inline with Markdown.

8. Provider-aware actions
   GitLab repos show GL badge and suppress GitHub-only actions
   (Create Issue FAB, star/unstar). Actions always match the provider.
```

---

## 11. Open Source Strategy

RepoSphere is built in the open. The core product is open source.
Revenue comes from the hosted SaaS (auth, sync, teams, subscriptions).

```
Open source (free forever):
  - Self-hosted version
  - Core repo viewer + file browser + commit/PR/issue viewer
  - Single provider, local token storage
  - Repo pinning + GitLab read access

Closed / SaaS only:
  - Multi-provider sync via backend
  - Team workspaces
  - Notifications infrastructure
  - Mobile push notifications
  - Analytics dashboard
```

---

## 12. Configuration Reference

```dart
// lib/core/config/app_config.dart
class AppConfig {
  // GitHub OAuth App client_id (device flow — no secret needed)
  static const githubClientId = '';

  // Supabase project URL and anon key
  static const supabaseUrl = '';
  static const supabaseAnonKey = '';

  static bool get hasGitHubOAuth => githubClientId.isNotEmpty;
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

class StorageKeys {
  static const githubToken = 'github_pat';
  static const githubUserLogin = 'github_user_login';
  static const gitlabToken = 'gitlab_pat';
}
```

**To enable Device Flow:**
1. github.com/settings/developers → OAuth Apps → New OAuth App
2. Set Homepage URL + callback URL (http://localhost for device flow)
3. Copy Client ID → `AppConfig.githubClientId`
4. No client secret needed

**To enable GitLab:**
- User enters their GitLab PAT in the auth/settings screen
- Token stored in SecureStorage under `StorageKeys.gitlabToken`
- Repos appear automatically in the unified list with an orange GL badge

**To enable Supabase:**
1. Create a Supabase project, enable GitHub OAuth provider
2. Fill `AppConfig.supabaseUrl` + `AppConfig.supabaseAnonKey`
3. Add redirect URL to Supabase dashboard
