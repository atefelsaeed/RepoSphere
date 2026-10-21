# Architecture

A short tour for people who want to read or extend the code. The older, longer [product spec](PRODUCT_SPEC.md) is kept for history; this page describes the code as it is today.

## Big picture

```
        ┌──────────────┐
        │  Flutter UI  │  screens, Riverpod providers
        └──────┬───────┘
               │ talks only to
               ▼
        ┌──────────────┐   capabilities: "can this provider approve? merge? show a diff?"
        │ GitProvider  │◄──────────────────────────────────────────────────────────────┐
        └──────┬───────┘                                                                │
   ┌───────────┼──────────────┬─────────────────┬────────────────┐                      │
   ▼           ▼              ▼                 ▼                │  UI hides what       │
 GitHub     GitLab       Azure DevOps     Forgejo / Gitea        │  a provider can't do │
 adapter    adapter      adapter          adapter                │                      │
   │           │              │                 │                └──────────────────────┘
   └───────────┴──── REST ────┴─────────────────┘   straight to each host, no proxy
```

- **No backend.** Everything runs on the device and calls the Git hosts directly.
- **One interface.** Screens depend on `GitProvider` (`lib/features/repos/domain/repositories/git_provider.dart`), never on a specific API. Each adapter (`data/repositories/*_repo_repository_impl.dart`) maps its host's JSON into shared entities (`domain/entities/`).
- **Capabilities.** `ProviderCapabilities` declares what an adapter supports; widgets check it instead of testing "is this GitHub?".
- **Inbox-only providers.** `InboxOnlyProvider` is a base class for adapters that only implement the Inbox (Forgejo / Gitea today): four methods instead of the whole interface.

## Code layout

```
lib/
  core/              router, theme, locale provider, shared types
  features/
    auth/            GitConnection, secure token storage, keychain migration, connect form
    repos/
      domain/        entities + GitProvider interface
      data/          datasources (REST clients), adapters, inbox loader/cache, dismissal store
      presentation/  Riverpod providers, screens, widgets
    notifications/   background check + local notifications
  l10n/              generated localizations (en, ar)
  shared/            error view, shimmer
tool/                icon + string-table generators (see CONTRIBUTING)
test/                unit, adapter (mocked HTTP), widget tests
```

## How the Inbox works

1. `activeProvidersProvider` builds one `GitProvider` per saved `GitConnection`.
2. `loadInbox` (`data/inbox_loader.dart`) calls `getInboxItems()` on all of them concurrently.
3. Each adapter runs several small queries (review requests, assignments, mentions, my PRs needing work) through `collectInbox`: a failing query is reported as *partial*; if **every** query fails the error is rethrown so the UI never shows a false "all clear".
4. `InboxItem.mergeAndSort` merges duplicates and orders by the most urgent reason.
5. The UI layers filters on top (workspace, account, reason) and hides items the user marked done/snoozed.
6. The last good result is cached so the app opens instantly.

## Background alerts

`features/notifications/background_inbox_check.dart` registers a Workmanager periodic task. It re-uses the same `loadInbox`, filters out dismissed items, and `planAlerts` (a pure function) decides what is **newly** urgent compared to what it already told you about. Localisation there uses the saved language, since there is no `BuildContext` in the background.

## Storage

| What | Where |
|---|---|
| Tokens (`GitConnection` list) | `flutter_secure_storage` (`SecureTokenStorage`), iOS keychain class `first_unlock` |
| Workspaces, dismissals, Inbox cache, theme, language, alert state | `shared_preferences` |

Changing the iOS keychain accessibility is a delete-then-add inside the plugin, so `KeychainMigration` backs the value up, verifies each step, never throws, and lets readers fall back to the backup.

## Localisation

`tool/gen_arb.py` (+ `tool/strings_legacy.py`) is the single table of strings with English and Arabic side by side. It writes the ARB files; `flutter gen-l10n` generates `lib/l10n/*.dart`. A test fails if a key is missing in one language, placeholders differ, or a widget hard-codes an English label.

## Testing approach

- Adapters are tested with `package:http/testing.dart`: assert the request *and* the mapped result, including failures.
- Pure logic (`planAlerts`, `Workspace.resolve`, `parseGitDiff`, `InboxItem.mergeAndSort`) is tested without a device.
- Anything that can lose user data (keychain migration) is tested with injected faults.
- Widget tests use a scriptable `FakeProvider` (`test/support`).

## Adding a provider

Short version: write a datasource, extend `InboxOnlyProvider` (or implement `GitProvider`), register it in `buildGitProvider`, add it to the connect form, add strings, add tests. The step-by-step checklist is in [CONTRIBUTING.md](../CONTRIBUTING.md#adding-or-extending-a-provider).
