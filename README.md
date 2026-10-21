# RepoSphere

[![CI](https://github.com/atefelsaeed/RepoSphere/actions/workflows/ci.yml/badge.svg)](https://github.com/atefelsaeed/RepoSphere/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)

**Live demo:** [atefelsaeed.github.io/RepoSphere](https://atefelsaeed.github.io/RepoSphere/) · **Author:** [Atef Elsaeed](https://atefelsaeed.github.io)

**One inbox for everything that needs you across GitHub, GitLab and Azure DevOps.**

Most Git tools answer *"where are my repos?"*. RepoSphere answers *"what do I need to do today?"* — failing CI, requested changes, review requests, assignments and mentions from **every account and provider**, in a single prioritised list you can act on without opening a browser.

It is built for people who work across many accounts — freelancers and agencies with a personal login, an org per client, and a self-hosted GitLab for the client who insists.

<p align="center">
  <img src="doc/screenshots/inbox-dark.png" width="250" alt="Unified Inbox across GitHub and GitLab, dark theme">
  <img src="doc/screenshots/inbox-actions-dark.png" width="250" alt="Quick actions: re-run CI, approve, request changes, merge">
  <img src="doc/screenshots/inbox-workspace-light.png" width="250" alt="Inbox filtered to one client workspace, light theme">
</p>
<p align="center"><sub>Demo data. Left to right: everything that needs you, act without opening a browser, one client at a time.</sub></p>

> **Status: alpha.** Built with Flutter for web, macOS, Windows, Linux, Android and iOS. Expect rough edges — see [CHANGELOG.md](CHANGELOG.md).

## What it does

- **Unified Inbox** — everything urgent, most urgent first: CI failed → changes requested → merge conflicts → review requested → assigned → mentioned. The same PR found by several queries shows up once, with every reason.
- **Read and act in place** — open an item to see its description, changed files with a coloured diff and the discussion (GitHub and GitLab), then approve, request changes, merge, or re-run failed CI without leaving the app.
- **Clear it out** — swipe to mark done (it comes back only if there's new activity) or snooze until later today, tomorrow or next week.
- **Workspaces per client** — group whole accounts *and/or* specific orgs or groups under a client name and colour. One GitHub login can serve several clients; filter the Inbox to one client at a time.
- **Multi-account, multi-provider** — connect any number of GitHub, GitLab, Azure DevOps and Forgejo / Gitea accounts (including **self-hosted** servers) at once.
- **Urgent alerts on mobile** — optional background check that notifies you about *newly* urgent items only. No server involved.
- **Arabic and English** — full right-to-left layout and Arabic notifications; switch in Settings. The repository browser is translated too.
- **Fast and tolerant** — opens instantly from the last snapshot. If one account fails (expired token, offline) you get a banner naming it, not a false "all clear".
- **Also a repo browser** — repos, file tree with syntax highlighting, commits and diffs, PRs/MRs, issues/work items, releases, activity.

### What each provider supports

| | GitHub | GitLab | Azure DevOps | Forgejo / Gitea |
|---|:-:|:-:|:-:|:-:|
| Inbox: review requests, assignments, mentions | ✅ | ✅ | PRs and work items (no mentions) | ✅ |
| CI failed / changes requested / conflicts on **your** PRs | ✅ | ✅ | changes requested (no CI status) | ✅ |
| Open an item in-app (description, diff, discussion) | ✅ | ✅ | ✅ (changed files, no line diff) | ✅ |
| Approve | ✅ | ✅ | ✅ | ✅ |
| Request changes | ✅ | — | ✅ | ✅ |
| Merge | ✅ | ✅ | ✅ | ✅ |
| Re-run failed CI | ✅ | ✅ | — | — |
| Repo browser | ✅ | ✅ | ✅ | — |

GitLab has no request-changes call in its REST API. Azure DevOps exposes changed files but not a ready-made line diff, so its detail view lists files without hunks. Forgejo / Gitea (including Codeberg and self-hosted servers) covers the Inbox only for now. Bitbucket is planned.

## Privacy

- Your tokens are stored **on your device** in the platform secure store (Keychain on iOS and macOS, Keystore-backed storage on Android, Credential Manager on Windows, the system secret service on Linux, local storage on web). There is no RepoSphere backend.
- The app talks **directly** to GitHub, GitLab and Azure DevOps (or your self-hosted GitLab). Nothing is proxied.
- Crash reporting through Sentry is **off** unless you build with your own `SENTRY_DSN`.
- Workspaces, snoozes and the Inbox snapshot are stored locally and are not synced between devices.

## Run it anywhere

| Platform | How |
|---|---|
| **Web** | Open the [live demo](https://atefelsaeed.github.io/RepoSphere/) (published from `main` by `.github/workflows/deploy-web.yml`), or run it yourself. |
| **macOS** | Download `RepoSphere-macos.zip` from [Releases](https://github.com/atefelsaeed/RepoSphere/releases), unzip, then right-click the app → *Open* the first time. The build is not notarised, so Gatekeeper blocks a plain double-click. |
| **Windows** | Download `RepoSphere-windows-x64.zip`, unzip, run `repo_sphere.exe`. SmartScreen may warn because the build is unsigned: *More info → Run anyway*. |
| **Linux** | Download `RepoSphere-linux-x64.tar.gz`, extract, run `./repo_sphere`. Needs GTK 3 and `libsecret` plus a running secret service (GNOME Keyring or KWallet) so tokens can be stored. |
| **Android** | Download `RepoSphere-android.apk` and sideload it. It is signed with a debug key, so it's for testing, not the Play Store. |
| **iOS** | Build from source with Xcode (no App Store build yet). |

Release assets are produced by `.github/workflows/release.yml` when a `v*` tag is pushed. Until the first release is tagged, build from source below.

**Web notes**

- GitHub, GitLab.com and Azure DevOps all allow browser requests, so the web build works for them. A **self-hosted GitLab** works only if your instance allows cross-origin API calls from the site you open the app on.
- Tokens are kept in the browser's local storage on that device. Prefer the desktop or mobile apps for long-lived tokens, and never use the web build on a shared computer.

## Getting started


Requires Flutter **3.41 or newer** (the dependency lockfile needs Dart 3.11).

```bash
git clone https://github.com/atefelsaeed/RepoSphere.git
cd RepoSphere
flutter pub get
flutter run -d chrome        # or: -d macos / windows / linux, or a simulator/emulator
```

On first launch pick your provider (GitHub, GitLab — including a self-hosted URL — or Azure DevOps) and connect with a Personal Access Token. Add more accounts any time from **Settings → Add account**.

### Tokens

| Provider | Create a token with | Notes |
|---|---|---|
| **GitHub** | classic PAT, scopes `repo`, `read:user`, `notifications`, `gist` | `repo` also covers approving, merging and re-running CI |
| **GitLab** | PAT, scopes `api`, `read_user` | For self-hosted, enter your instance URL, e.g. `https://gitlab.example.com` |
| **Azure DevOps** | PAT with Code (read) and Work Items (read) | Enter your organisation URL, e.g. `https://dev.azure.com/your-org` |

Use the least-privileged token that works for you, and revoke it when you stop using the app.

### Mobile alerts

Turn on **Settings → Urgent inbox alerts** (mobile only). It asks for notification permission, then checks in the background about every 30 minutes and notifies you only about items that *newly* became urgent.

- Android runs the check roughly on schedule.
- iOS decides when background work runs and may run it far less often, sometimes not for hours. **Check now** in Settings runs it immediately so you can verify your setup.
- On iOS, saved tokens are moved to a keychain class readable while the phone is locked the first time you open the app after updating. Until then, background checks can fail on a locked phone.

## Architecture

Clean architecture — `domain / data / presentation` — with one capability-based interface in front of every provider. Screens talk to `GitProvider`, never to a specific API.

```
GitConnection ──► buildGitProvider ──► GitProvider
                                        ├── GitHubRepoRepositoryImpl
                                        ├── GitLabRepoRepositoryImpl
                                        └── AzureRepoRepositoryImpl
```

- `ProviderCapabilities` lets the UI hide what a provider can't do.
- The Inbox is `GitProvider.getInboxItems()` per account, merged and prioritised by `InboxItem.mergeAndSort`. The same loader feeds the UI and the background check.
- Quick actions are `GitProvider.performPrAction`.

More detail in [doc/PRODUCT_SPEC.md](doc/PRODUCT_SPEC.md) and the backlog in [doc/IMPROVEMENTS.md](doc/IMPROVEMENTS.md).

### Tech stack

Flutter · Riverpod 2 · GoRouter · `http` · `flutter_secure_storage` · `shared_preferences` · Workmanager + local notifications.

## Keyboard shortcuts

On the repositories screen: `/` search, `R` refresh, `?` help, `Esc` back.

## Optional configuration

Lives in `lib/core/config/app_config.dart`:

- `githubClientId` enables "Sign in with GitHub" through the OAuth Device Flow (no client secret needed).
- `supabaseUrl` and `supabaseAnonKey` enable optional Supabase auth.
- Sentry crash reporting: pass `--dart-define=SENTRY_DSN=...` at build time.

## Tests and CI

```bash
flutter test
flutter analyze
```

GitHub Actions runs analysis, tests and builds for web, macOS, Windows, Linux and Android on every push and pull request. Pushes to `main` also deploy the web demo to GitHub Pages. Pushing a `v*` tag builds every platform and publishes a release.

## Roadmap

- Real-account hardening of the Inbox
- Bitbucket; repository browser for Forgejo / Gitea; Azure DevOps mentions and CI status
- Home-screen widget with the urgent count
- Inline review comments and file-level review in the in-app PR view
- More languages
- Signed and notarised desktop builds, App Store / Play Store releases

## License

[MIT](LICENSE) © 2026 Atef Mahmoud Elsaeed

## Contributing

Issues and pull requests are welcome — start with [CONTRIBUTING.md](CONTRIBUTING.md). Adding another provider (Bitbucket, Gitea) is a good first big contribution.

## Known limitations

- Alpha: expect bugs, and test against throwaway data before trusting actions like Merge.
- The Inbox has been exercised against mocked API responses and demo data; reports from real-world accounts are very welcome.
- Azure DevOps uses the PR creation date as its activity time, because its list API has no "last updated".
- No home-screen widget yet; no sync between devices.
