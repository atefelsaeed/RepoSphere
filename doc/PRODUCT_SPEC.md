# RepoSphere — Product & Architecture Spec
> Version 2.0 | Last updated: April 2026

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

Durations:
  Micro:    150-160ms (hover transitions)
  Standard: 250-300ms (list items, section entrances)
  Slow:     350ms     (page-level content fade)
```

---

## 5. Architecture

### 5.1 Project Structure

```
lib/
├── core/
│   ├── router/           GoRouter + _RouterNotifier (auth redirect)
│   │                     13 named routes
│   ├── theme/            AppTheme — dark + light ThemeData, AppColors
│   ├── providers/        themeModeProvider (StateProvider<ThemeMode>)
│   ├── constants/        AppConstants (API base), kLanguageColors map
│   └── utils/            GitHubAuthException, GitHubRateLimitException
│
├── features/
│   ├── auth/
│   │   ├── data/         SecureTokenStorage (flutter_secure_storage)
│   │   └── presentation/ AuthScreen + AuthNotifier
│   │
│   └── repos/
│       ├── domain/
│       │   ├── entities/ RepoEntity, UserEntity, CommitEntity,
│       │   │             CommitDetailEntity, BranchEntity,
│       │   │             PullRequestEntity, IssueEntity,
│       │   │             RepoContentItem, FileContent
│       │   └── repos/    GitProvider (abstract interface)
│       │
│       ├── data/
│       │   ├── models/   RepoModel, UserModel, CommitModel,
│       │   │             CommitDetailModel, BranchModel,
│       │   │             PullRequestModel, IssueModel
│       │   ├── datasources/  GitHubRemoteDatasource (10 API methods)
│       │   └── repositories/ GitHubRepoRepositoryImpl
│       │
│       └── presentation/
│           ├── screens/  ReposScreen, RepoDetailScreen,
│           │             RepoBrowserScreen, FileViewerScreen,
│           │             RepoCommitsScreen, CommitDetailScreen,
│           │             RepoPrsScreen, RepoPrDetailScreen,
│           │             RepoIssuesScreen, RepoIssueDetailScreen,
│           │             RepoReadmeScreen, ProfileScreen
│           │
│           ├── providers/ repos_provider (filter, sort, search),
│           │             commits_notifier (paginated),
│           │             commit_detail_provider,
│           │             repo_branches_provider,
│           │             repo_commits_provider,
│           │             repo_prs_provider (paginated),
│           │             repo_issues_provider (paginated),
│           │             repo_readme_provider,
│           │             repo_contents_provider
│           │
│           └── widgets/  RepoCard (hover-aware StatefulWidget),
│                         CommitTile, LabelChip
│
├── shared/
│   └── widgets/          ErrorView, ShimmerBox, ShimmerRepoCard,
│                         ShimmerListTile
│
├── app.dart              RepoSphereApp (themeModeProvider wired)
└── main.dart
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
// 🔜 GitLabRepoRepositoryImpl   (Phase 2)
// 🔜 BitbucketRepoRepositoryImpl (Phase 2)
```

### 5.3 State Management (Riverpod 2.x)

```
Core:
  authProvider              AsyncNotifier<String?>
  githubDatasourceProvider  Provider<GitHubRemoteDatasource?>
  gitProviderProvider       Provider<GitProvider?>
  themeModeProvider         StateProvider<ThemeMode>

User & Repos:
  currentUserProvider       FutureProvider<UserEntity?>
  allReposProvider          FutureProvider<List<RepoEntity>>
  starredReposProvider      FutureProvider<List<RepoEntity>>
  filteredReposProvider     Provider<AsyncValue<List<RepoEntity>>>
  repoFilterProvider        StateProvider<RepoFilter>
  searchQueryProvider       StateProvider<String>
  repoSortProvider          StateProvider<RepoSort>

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
```

### 5.4 Pagination Pattern

Commits, PRs, and Issues all use the same `StateNotifier` pagination pattern:

```dart
// State holds: items list, isLoading, isLoadingMore, hasMore, error, filter
// Notifier exposes: loadMore(), refresh(), changeBranch/changeFilter()
// UI: scroll listener triggers loadMore() at maxScrollExtent - 300px
//     "load more" slot at end of list shows ShimmerListTile while loading
```

### 5.5 Architecture Evolution by Phase

```
Phase 1 (MVP — ✅ complete):
  Flutter App ──► GitHub REST API v3
                  Local SecureStorage (PAT token)

Phase 2 (SaaS):
  Flutter App ──► Supabase Auth
              ──► GitHub OAuth / GitLab OAuth
              ──► Supabase DB (encrypted tokens per user)
              ──► Supabase Edge Functions (API proxy)

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
✅ GoRouter with auth-based redirect guard
✅ GitHub PAT token auth (secure storage)
✅ Dark + Light + System theme with toggle in AppBar
✅ Error views with retry across all screens
✅ Responsive grid (1→2→3→4 columns based on width)
```

#### Repos List Screen
```
✅ All repos (owner + collaborator + org member)
✅ Starred repos tab
✅ Filter chips: All / Owned / Forked / Starred / Public / Private
✅ Sort dropdown: Last Updated / Stars / Name / Created
✅ Live search (name + description + language)
✅ Animated repo count badge
✅ Shimmer skeleton grid on load
✅ Staggered card entrance animations
✅ Pull-to-refresh
```

#### Repo Card
```
✅ Owner avatar + full name
✅ Private badge
✅ Language dot + name
✅ Fork indicator
✅ Star count
✅ Last updated (timeago)
✅ Copy link button
✅ Open on GitHub button
✅ Hover lift effect (border + glow shadow)
✅ Spring filter chip animation on select
```

#### Repo Detail Screen
```
✅ Owner avatar + name + repo name
✅ Public / Private chip
✅ Description
✅ Stats row: Stars / Forks / Watchers / Open Issues
✅ Quick nav buttons: PRs / Issues / README / Commits / Browse
      → Each button has per-accent hover glow
✅ Language + Fork + Branch info chips
✅ Topics
✅ Created / Last updated dates
✅ Recent commits section (3 commits with shimmer on load)
✅ "View all" → in-app commits screen
✅ Copy link + Open on GitHub in AppBar
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
✅ Title + state badge (colored pill)
✅ Author avatar + opened timeago
✅ head → base branch info box
✅ Labels row
✅ Full PR body rendered in Markdown
✅ "No description" fallback
✅ "View N comments on GitHub" footer button
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
✅ Shimmer skeleton on load
✅ Staggered animation
✅ Pull-to-refresh
```

#### Issue Detail Screen
```
✅ Title + state badge (green/purple)
✅ Author avatar + timeago
✅ Labels row
✅ Full issue body rendered in Markdown
✅ "No description" fallback
✅ "View N comments on GitHub" footer button
✅ Open on GitHub in AppBar
✅ Staggered section animations
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
✅ Accessible via avatar tap in repos AppBar
```

### Phase 2 — SaaS Foundation `[Next]`

```
Auth:
  ⬜ Supabase project setup
  ⬜ Email/Password signup + login
  ⬜ GitHub OAuth (replace PAT)
  ⬜ GitLab OAuth
  ⬜ "Forgot password" flow

Provider Management:
  ⬜ Provider connection screen
  ⬜ Connected providers list
  ⬜ Multi-provider repo aggregation

User Account:
  ⬜ Subscription status badge on profile
  ⬜ Connected providers overview
```

### Phase 3 — Power Features

```
Repo Management:
  ⬜ PR Review (view diff, approve, request changes, comment)
  ⬜ Issues: create, assign, label, close
  ⬜ Repo pinning (dashboard favorites)
  ⬜ Custom collections (group repos by project/client)
  ⬜ Code diff viewer (compare branches/commits)

Discovery:
  ⬜ Global search (across all connected providers)
  ⬜ Activity feed (all events across all repos)
  ⬜ Notification center (PRs, issues, mentions)

Multi-Provider:
  ⬜ GitLab repos + commits + MRs
  ⬜ Bitbucket repos + PRs
  ⬜ Provider badge on each repo card
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
✅ GET /user                                    Current user (login, name, bio,
                                                location, company, email, blog,
                                                repos, followers, following,
                                                created_at)
✅ GET /user/repos                              All repos (owner + collaborator
                                                + org member)
✅ GET /user/starred                            Starred repos
✅ GET /repos/{owner}/{repo}/branches           Branch list (for branch selector)
✅ GET /repos/{owner}/{repo}/commits            Paginated commit history
✅ GET /repos/{owner}/{repo}/commits/{sha}      Commit detail + files changed
✅ GET /repos/{owner}/{repo}/pulls              Paginated PRs (open/closed/merged)
✅ GET /repos/{owner}/{repo}/issues             Paginated issues (open/closed)
✅ GET /repos/{owner}/{repo}/readme             README (base64 decoded)
✅ GET /repos/{owner}/{repo}/contents/{path}    File browser + file content

Planned:
⬜ POST /repos/{owner}/{repo}/issues            Create issue
⬜ POST /repos/{owner}/{repo}/issues/{n}/comments  Comment on issue
⬜ POST /repos/{owner}/{repo}/pulls/{n}/reviews    Review PR
⬜ GET  /repos/{owner}/{repo}/compare/{b}...{h}   Diff view
⬜ GET  /notifications                          Notification feed
⬜ GET  /search/repositories                   Global search
```

---

## 8. Tech Stack

```
Frontend:
  Framework:        Flutter 3.x (multi-platform)
  State:            Riverpod 2.x (Provider, FutureProvider.family,
                                  StateNotifierProvider.family,
                                  StateProvider, AsyncNotifier)
  Navigation:       GoRouter 14.x (named routes, auth redirect)
  HTTP:             http (→ dio in Phase 2 for interceptors + retry)
  Auth storage:     flutter_secure_storage (Keychain / EncryptedSharedPrefs)
  Animations:       flutter_animate (stagger, fade, slide, scale)
  Loading:          shimmer (3 custom shimmer widgets)
  Markdown:         flutter_markdown_plus
  Code highlight:   flutter_highlight (atom-one dark/light)
  Open URLs:        url_launcher
  Time display:     timeago
  Font:             google_fonts (Inter)

Backend (Phase 2+):
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

## 9. UX Principles

```
1. Zero friction
   Value within 60 seconds. Connect token → see repos immediately.
   No long onboarding flows.

2. Information hierarchy
   Repo name, language, last updated visible without any clicks.
   Stars, forks, issues on card. Details on demand.

3. Dark first
   Developers live in dark mode. Light is the alternative.
   Toggle: System → Light → Dark → System (remembers per session).

4. Speed perception
   No blank states. Shimmer skeletons appear instantly.
   Staggered list animations give a sense of progressive loading.

5. Keyboard friendly (planned)
   / to focus search.
   Arrow keys to navigate lists.

6. Responsive by default
   4-column grid ≥1200px → 3 ≥900px → 2 ≥600px → 1 on mobile.
   Every screen works at 375px and 1440px.

7. In-app everything
   No links that kick users to GitHub for content we can show.
   PRs, Issues, Commits, READMEs, Files — all in-app.
```

---

## 10. Open Source Strategy

RepoSphere is built in the open. The core product is open source.
Revenue comes from the hosted SaaS (auth, sync, teams, subscriptions).

```
Open source (free forever):
  - Self-hosted version
  - Core repo viewer + file browser + commit/PR/issue viewer
  - Single provider, local token storage

Closed / SaaS only:
  - Multi-provider sync via backend
  - Team workspaces
  - Notifications infrastructure
  - Mobile push notifications
  - Analytics dashboard
```

---

## 11. Next Steps (Phase 2 Kickoff)

In order:

1. `⬜` Add `shared_preferences` — persist theme preference across sessions
2. `⬜` Supabase project setup + auth schema
3. `⬜` GitHub OAuth flow (device flow or web redirect)
4. `⬜` Replace PAT screen with OAuth "Connect GitHub" button
5. `⬜` Token stored in Supabase (encrypted) instead of local storage
6. `⬜` GitLab OAuth + API adapter
7. `⬜` Provider management screen (connect / disconnect)
8. `⬜` Multi-provider repo aggregation with provider badge on cards
