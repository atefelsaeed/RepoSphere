# RepoSphere

**All your Git repositories in one dashboard, across GitHub and GitLab.**

RepoSphere is an open-source Flutter app for developers who work on many repositories across more than one Git provider: freelancers with several clients, agency developers, and tech leads keeping an eye on a team. Instead of switching between tabs and accounts, you see repos, commits, pull requests, issues, releases, notifications and gists from one place.

[![CI](https://github.com/atefelsaeed/RepoSphere/actions/workflows/ci.yml/badge.svg)](https://github.com/atefelsaeed/RepoSphere/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B?logo=flutter)

**Live demo:** [atefelsaeed.github.io/RepoSphere](https://atefelsaeed.github.io/RepoSphere/) · **Author:** [Atef Elsaeed](https://atefelsaeed.github.io)

> Status: in active development. GitHub and GitLab work today; multiple accounts per provider is the next milestone (see [the backlog](doc/IMPROVEMENTS.md)).

## Features

| Area | What you can do |
| --- | --- |
| Repositories | Repos from GitHub and GitLab in one list; filter, sort, search, pin and star; infinite scroll for large accounts |
| Code | Browse files with a branch selector and breadcrumbs; syntax highlighting for 20+ languages; rendered READMEs |
| Commits | Paginated history per branch; full commit diff with added and removed lines |
| Pull requests & issues | Open, closed and merged tabs; comment threads; create an issue |
| Releases | Release notes rendered as Markdown |
| You | Activity feed, notifications with unread badge, gists, profile |
| Search | Search all of GitHub, with recent searches remembered |
| Everywhere | Light and dark themes, keyboard shortcuts (`/` search, `R` refresh, `?` help, `Esc` back), installable as a PWA |

## Architecture

Clean Architecture, organized by feature:

```
lib/
├── core/            config, router, theme, shared providers, error types
├── features/
│   ├── auth/        GitHub Device Flow, Supabase auth, secure token storage
│   └── repos/
│       ├── domain/        entities and repository contracts
│       ├── data/          GitHub and GitLab data sources, models, repository
│       └── presentation/  screens, widgets, Riverpod providers
└── shared/          reusable widgets (error view, shimmer loaders)
```

A few decisions worth calling out:

- **One repository, one data source per provider.** GitHub and GitLab each have their own data source and models, mapped to shared domain entities. GitLab was added without changing the screens, and the same seam is where Bitbucket or a second account would plug in.
- **Errors handled in one place.** Every HTTP status is mapped to a typed exception with a readable message (rate limits include the reset time). A global Riverpod `ProviderObserver` catches an expired token anywhere in the app and signs the user out, so screens never deal with it individually.
- **No secrets in the client.** GitHub sign-in uses the OAuth Device Flow, which needs no client secret. Tokens are kept in platform secure storage. Sentry's DSN comes from a build-time environment variable.
- **Web first, multi-platform.** The same codebase targets web, Android, iOS, macOS, Windows and Linux.

Full product and architecture notes: [doc/PRODUCT_SPEC.md](doc/PRODUCT_SPEC.md).

## Tech stack

Flutter · Riverpod · GoRouter · `http` · flutter_secure_storage · shared_preferences · Supabase (optional auth) · Sentry · flutter_markdown_plus · flutter_highlight · flutter_animate

## Run it locally

Requires Flutter 3.38 or newer.

```bash
git clone https://github.com/atefelsaeed/RepoSphere.git
cd RepoSphere
flutter pub get
flutter run -d chrome
```

Sign in with a GitHub personal access token (scopes: `repo`, `notifications`, `gist`). To connect GitLab, open **Settings** and add a GitLab token.

Optional configuration lives in `lib/core/config/app_config.dart`:

- `githubClientId`: enables "Sign in with GitHub" through the Device Flow
- `supabaseUrl` and `supabaseAnonKey`: enables Supabase auth
- Sentry: pass `--dart-define=SENTRY_DSN=...` at build time

## Tests and CI

```bash
flutter test
dart analyze lib/
```

GitHub Actions runs static analysis, tests and a release web build on every push and pull request. Pushes to `main` also deploy the web demo to GitHub Pages.

## Roadmap

- Multiple accounts per provider, with an account badge on every repo
- App icon for all platforms
- Arabic and English localization
- Pull request review: view the diff, approve, request changes

## License

[MIT](LICENSE) © 2026 Atef Mahmoud Elsaeed
