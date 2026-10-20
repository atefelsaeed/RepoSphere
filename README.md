# RepoSphere

**One inbox for everything that needs you across GitHub, GitLab and Azure DevOps.**

Most Git tools answer *"where are my repos?"*. RepoSphere answers *"what do I need to do today?"* — failing CI, requested changes, review requests, assignments and mentions from **every account and provider**, in a single prioritised list you can act on without opening a browser.

It is built for people who work across many accounts — freelancers and agencies with a personal login, an org per client, and a self-hosted GitLab for the client who insists.

> **Status: alpha.** Built with Flutter. Web, iOS and Android build today; the macOS, Linux and Windows runners exist but are untested. Expect rough edges — see [CHANGELOG.md](CHANGELOG.md).

## What it does

- **Unified Inbox** — everything urgent, most urgent first: CI failed → changes requested → merge conflicts → review requested → assigned → mentioned. The same PR found by several queries shows up once, with every reason.
- **Act in place** — approve, request changes, merge, or re-run failed CI from the item itself.
- **Clear it out** — swipe to mark done (it comes back only if there's new activity) or snooze until later today, tomorrow or next week.
- **Workspaces per client** — group whole accounts *and/or* specific orgs or groups under a client name and colour. One GitHub login can serve several clients; filter the Inbox to one client at a time.
- **Multi-account, multi-provider** — connect any number of GitHub, GitLab (including **self-hosted**) and Azure DevOps accounts at once.
- **Urgent alerts on mobile** — optional background check that notifies you about *newly* urgent items only. No server involved.
- **Fast and tolerant** — opens instantly from the last snapshot. If one account fails (expired token, offline) you get a banner naming it, not a false "all clear".
- **Also a repo browser** — repos, file tree with syntax highlighting, commits and diffs, PRs/MRs, issues/work items, releases, activity.

### What each provider supports

| | GitHub | GitLab | Azure DevOps |
|---|:-:|:-:|:-:|
| Inbox (review requests, assignments, mentions) | ✅ | ✅ | ✅ (PRs and work items; no mentions) |
| CI failed / changes requested / conflicts on **your** PRs | ✅ | ✅ | changes requested + conflicts (no CI status) |
| Approve | ✅ | ✅ | — |
| Request changes | ✅ | — | — |
| Merge | ✅ | ✅ | — |
| Re-run failed CI | ✅ | ✅ | — |
| Repo browser | ✅ | ✅ | ✅ |

GitLab has no request-changes call in its REST API, and Azure DevOps actions are not implemented yet. Bitbucket and Gitea/Forgejo are planned.

## Privacy

- Your tokens are stored **on your device** in the platform secure store (iOS Keychain, Android Keystore-backed storage). There is no RepoSphere backend.
- The app talks **directly** to GitHub, GitLab and Azure DevOps (or your self-hosted GitLab). Nothing is proxied.
- Crash reporting through Sentry is **off** unless you build with your own `SENTRY_DSN`.
- Workspaces, snoozes and the Inbox snapshot are stored locally and are not synced between devices.

## Getting started

Requires a recent stable [Flutter](https://docs.flutter.dev/get-started/install) (developed on 3.41).

```bash
git clone https://github.com/atefelsaeed/RepoSphere.git
cd RepoSphere
flutter pub get
flutter run -d chrome        # or an iOS simulator / Android emulator
```

On first launch connect a GitHub account with a Personal Access Token. Add GitLab and Azure DevOps accounts afterwards from **Settings → Add account**.

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

## Contributing

Issues and pull requests are welcome — start with [CONTRIBUTING.md](CONTRIBUTING.md). Adding another provider (Bitbucket, Gitea) is a good first big contribution.

## Known limitations

- Alpha: expect bugs, and test against throwaway data before trusting actions like Merge.
- The Inbox has been exercised against mocked API responses and demo data; reports from real-world accounts are very welcome.
- Azure DevOps uses the PR creation date as its activity time, because its list API has no "last updated".
- No home-screen widget yet; no sync between devices.
