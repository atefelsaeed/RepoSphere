# Contributing to RepoSphere

Thanks for helping. RepoSphere is early (alpha), so small, focused changes that come with tests are the easiest to review.

By contributing you agree that your contributions are licensed under the project's [MIT License](LICENSE).

Start with the [architecture overview](doc/architecture.md); end users should read the [user guide](doc/user-guide.md) instead.

## Setup

```bash
flutter pub get
flutter analyze        # must be clean
flutter test           # must pass
flutter run -d chrome  # quickest way to see UI changes
```

You need Flutter 3.41 or newer. Mobile builds need Xcode (iOS) or the Android SDK. Linux desktop builds need `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libjsoncpp-dev libcurl4-openssl-dev`.

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

## Strings and translations

User-visible text lives in `tool/gen_arb.py` (English and Arabic side by side), never hard-coded in widgets.

1. Add or edit the entry in `tool/gen_arb.py`, then run `python3 tool/gen_arb.py` and `flutter gen-l10n`.
2. Use it with `context.l10n.yourKey` (`import '.../l10n/l10n.dart'`). Code that has no `BuildContext` (like background notifications) uses `lookupAppLocalizations(locale)`.
3. Use `AlignmentDirectional` / `EdgeInsetsDirectional` instead of left/right, and wrap code-like text (branch names, paths, diffs, `@login`) in `Directionality(textDirection: TextDirection.ltr, ...)`.
4. `test/unit/l10n_test.dart` fails if a key is missing in one language, placeholders differ, or a widget hard-codes an English label. Legacy screens' strings live in `tool/strings_legacy.py`; `tool/apply_l10n.py` and `tool/fix_const.py` are the helpers that moved them.

To add a language, add it to `tool/gen_arb.py` and `supportedLanguageCodes` in `lib/core/providers/locale_provider.dart`.

## Adding or extending a provider

1. Add the REST client in `data/datasources/` (thin: returns decoded JSON or models).
2. Implement `GitProvider` in `data/repositories/` — or, for a provider that only does the Inbox at first, extend `InboxOnlyProvider` (see the Forgejo / Gitea adapter) and implement just `getUser`, `getInboxItems`, `getItemDetail` and `performPrAction`;, mapping into the shared entities and declaring honest `ProviderCapabilities`. Operations you can't support throw `UnsupportedProviderOperation`.
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
- Text from Git hosts (PR/issue bodies, comments, READMEs) is written by other people. Open its links with `openExternalLink` (`lib/core/utils/external_link.dart`, http/https/mailto only), never `launchUrl(Uri.parse(href))`, and give every `Markdown`/`MarkdownBody` `imageBuilder: remoteMarkdownImage` so images load only on tap.
- Keep private repo names and URLs out of crash reports.
- Release signing: the *Release* workflow signs the Android APK when the `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` secrets exist, and falls back to the debug key otherwise. Locally, `android/key.properties` (git-ignored) does the same.
- Pin new GitHub Actions to a commit SHA with the tag in a comment; Dependabot keeps them current.
- If you find a vulnerability, please report it privately through GitHub's *Security → Report a vulnerability* on this repository rather than a public issue.

## Where help is most useful

- Trying the Inbox against **real accounts** and reporting what's wrong or missing (redact tokens and private repo names).
- Bitbucket and Gitea/Forgejo adapters.
- Azure DevOps inbox gaps: CI status, mentions, approve/merge.
- A home-screen widget for urgent counts.
- Tests for the screens (widget tests) — currently only logic is covered.
