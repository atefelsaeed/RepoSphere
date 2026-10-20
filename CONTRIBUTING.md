# Contributing to RepoSphere

Thanks for helping. RepoSphere is early (alpha), so small, focused changes that come with tests are the easiest to review.

## Setup

```bash
flutter pub get
flutter analyze        # must be clean
flutter test           # must pass
flutter run -d chrome  # quickest way to see UI changes
```

You need a recent stable Flutter (developed on 3.41). Mobile builds need Xcode (iOS) or the Android SDK.

To work on the Inbox without real accounts, point `connectionsProvider` and `activeProvidersProvider` at fake providers in a throwaway entry point — see `test/unit/inbox_test.dart` for how adapters are faked with `MockClient`.

## Project layout

```
lib/
  core/                 router, theme, shared types (GitProviderType)
  features/
    auth/               GitConnection, secure token storage, keychain migration
    repos/
      domain/           entities + the GitProvider interface
      data/             one datasource + adapter per provider, inbox loader
      presentation/     providers (Riverpod), screens, widgets
    notifications/      background inbox check + local notifications
test/unit/              adapter, inbox, workspace, migration tests
```

Rules of thumb:

- **Screens never call a provider's API directly.** They go through `GitProvider`.
- **Gate features on `ProviderCapabilities`**, not on `provider == github`.
- Providers map their API into the shared entities in `domain/entities/`.

## Adding or extending a provider

1. Add the REST client in `data/datasources/` (thin: returns decoded JSON or models).
2. Implement `GitProvider` in `data/repositories/`, mapping into the shared entities and declaring honest `ProviderCapabilities`. Operations you can't support throw `UnsupportedProviderOperation`.
3. Register it in `buildGitProvider` (`data/git_provider_factory.dart`) and in the add-account sheet in Settings.
4. For the Inbox, implement `getInboxItems()` with `collectInbox([...])`: it tolerates a failing query but rethrows when *every* query fails, so the UI never shows a false "all clear".
5. Add tests with `MockClient` covering the request you send and the mapping you return.

## Tests

- Network code is tested with `package:http/testing.dart` — assert both the request (method, path, headers) and the mapped result.
- Anything that can lose user data (like the keychain migration) is tested with injected faults. Follow that pattern for storage changes.
- Prefer pure functions for logic (see `planAlerts`, `Workspace.resolve`, `InboxItem.mergeAndSort`) so they can be tested without a device.

## Commits and pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`; optionally a scope, e.g. `feat(inbox): ...`.
- Keep a PR to one concern. Explain *why*, and say how you verified it.
- Before opening: `flutter analyze` is clean, `flutter test` passes, and you've added a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.
- UI changes: include a screenshot or short recording, in light and dark.

## Security

Tokens are the sensitive part of this app.

- Never log, print or send a token anywhere except the provider it belongs to.
- New persistence of secrets goes through `SecureTokenStorage`, never `shared_preferences`.
- If you find a vulnerability, please report it privately through GitHub's *Security → Report a vulnerability* on this repository rather than a public issue.

## Where help is most useful

- Trying the Inbox against **real accounts** and reporting what's wrong or missing (redact tokens and private repo names).
- Bitbucket and Gitea/Forgejo adapters.
- Azure DevOps inbox gaps: CI status, mentions, approve/merge.
- A home-screen widget for urgent counts.
- Tests for the screens (widget tests) — currently only logic is covered.
