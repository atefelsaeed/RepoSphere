# RepoSphere

A unified GitHub dashboard built with Flutter — browse repos, commits, PRs, issues, releases, activity, notifications, and gists from a single polished interface.

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
4. Enter a GitHub Personal Access Token with `repo` + `notifications` + `gists` scopes

## Architecture

Clean architecture — `domain / data / presentation` — documented in [doc/PRODUCT_SPEC.md](doc/PRODUCT_SPEC.md).

## Status

Phase 1 (MVP) is feature-complete. Phase 2 targets Supabase auth + GitHub OAuth + multi-provider support.
