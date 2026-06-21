# RepoSphere

A unified **multi-provider** Git workspace built with Flutter — follow all your work across **GitHub, GitLab, and Azure DevOps** (Bitbucket & self-hosted Gitea planned) from a single polished interface: repos, commits, PRs/MRs, issues/work-items, releases, activity, notifications, and gists.

## Providers

| Provider | Status |
|---|---|
| **GitHub** | ✅ Full read **+ write** (comment, merge PR, close issue, star, create issue) |
| **GitLab** | ✅ Full read (projects, commits + diff, MRs, issues, notes, releases, tree, files, todos, events) |
| **Azure DevOps** | ✅ Read (repos across the org, commits, PRs, **Work Items via WIQL**, files) |
| **Bitbucket / Gitea (self-hosted)** | 🔜 Planned — the unified adapter layer is built to accept them |

Multiple accounts per provider are supported — connect several GitHub orgs + a GitLab account + an Azure DevOps organisation at once.

## Features

- **Repos** — filter, sort, search, star/unstar with live toggle
- **File browser** — navigate directories with breadcrumb trail
- **File viewer** — syntax highlighting for 20+ languages
- **Commits** — paginated list with branch selector; full diff detail
- **Pull Requests** — open/closed/merged tabs; inline comment thread
- **Issues** — open/closed tabs; inline comment thread
- **Releases** — full release notes rendered in Markdown
- **Activity** — personal GitHub events feed
- **Notifications** — unread feed with mark-read support
- **Gists** — public/secret gists with file + language chips
- **Global Search** — search all of GitHub with recent history
- **Profile** — avatar, stats, bio

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.x (web-first, multi-platform) |
| State | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| HTTP | `http` package |
| Auth storage | `flutter_secure_storage` |
| Persistence | `shared_preferences` |
| Animations | `flutter_animate` + `shimmer` |
| Markdown | `flutter_markdown_plus` |
| Syntax | `flutter_highlight` |

## Getting Started

1. Clone the repo
2. `flutter pub get`
3. Run on web: `flutter run -d chrome`
4. Connect an account with a Personal Access Token:
   - **GitHub** — scopes `repo` + `read:user` + `notifications` + `gist`
   - **GitLab** — scopes `api` + `read_user` (set a base URL for self-hosted)
   - **Azure DevOps** — a PAT plus your organisation URL (e.g. `https://dev.azure.com/your-org`)

## Architecture

Clean architecture — `domain / data / presentation` — documented in [doc/PRODUCT_SPEC.md](doc/PRODUCT_SPEC.md).

Every provider sits behind one capability-based interface:

```
GitConnection ──► GitProviderFactory ──► GitProvider (capability-based)
                                          ├── GitHubRepoRepositoryImpl
                                          ├── GitLabRepoRepositoryImpl
                                          └── AzureRepoRepositoryImpl
```

Screens talk to `GitProvider`, never to a specific API. `ProviderCapabilities` lets the UI hide features a provider doesn't offer (e.g. Gists/Notifications for Azure, which exposes Work Items instead of Issues). Connections are stored as a multi-account list in `flutter_secure_storage`, with one-time migration from the old single-token keys.

## Status

- **Unified data layer — ✅ complete & unit-tested.** GitHub (read + write), GitLab (read), and Azure DevOps (read) all work behind one interface, with a multi-account connection registry. Covered by unit tests (MockClient) — `flutter analyze` clean, all tests green, web build passing.
- **UI wiring — ⏳ in progress.** Surfacing multi-account connect in Settings, the unified cross-provider repo list, routing every detail screen through the active connection, and a "My Work" aggregation screen. See [doc/IMPROVEMENTS.md](doc/IMPROVEMENTS.md).
