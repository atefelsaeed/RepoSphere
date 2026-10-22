# Security policy

RepoSphere handles personal access tokens for your Git hosts, so security reports are taken seriously. The project is **alpha** (pre-1.0): only the latest release and `main` receive fixes.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem. Use GitHub's private reporting instead: on this repository open **Security → Report a vulnerability**. Include the version or commit, the platform, what you did, what you expected and what happened. Redact tokens and private repository names from anything you attach.

You can expect an acknowledgement within a few days and a fix or a written assessment as soon as it can be reproduced. Credit is given in the [changelog](CHANGELOG.md) unless you prefer otherwise.

## How RepoSphere handles your data

There is **no RepoSphere server**. The app talks directly to the Git hosts you connect, so the main things to protect are your tokens and the text other people write on those hosts.

| Area | Behaviour |
|---|---|
| Tokens | Stored in the platform secure store (Keychain, Keystore-backed storage, Credential Manager, system secret service) and sent only to the host they belong to. |
| Links in PRs, issues, comments, READMEs | Opened only if they are `http`, `https` or `mailto` (`openExternalLink` in `lib/core/utils/external_link.dart`). Every link the app opens from provider data goes through it. |
| Images in that text | Never fetched until you tap *Load image from …*; Markdown is rendered only through `SafeMarkdown` / `SafeMarkdownBody`, and a test fails if a screen uses the raw widgets. |
| Self-hosted instances | `http://` is refused for public hosts; allowed only for localhost and private networks. |
| Several accounts | Inbox actions (approve, merge, re-run CI), starring and creating issues use the token of the account the item or repo belongs to; if that account is gone nothing is sent. Reading a GitHub repo's details (README, files, commits) still uses your first GitHub account, see the known limitations. |
| Disconnecting | Removing the last account deletes the tokens, the cached Inbox, dismissals, workspaces, search history and alert state, and stops background checks. |
| Android backup | `allowBackup` is off, so app data is not copied into Google backups. |
| Crash reports | Off unless you build with your own Sentry DSN; HTTP breadcrumbs are dropped. |
| CI / releases | Actions are pinned to commit SHAs, workflows default to read-only permissions, release tags are validated, SHA-256 checksums are published, and a release is refused rather than shipped signed with the debug key. |

## Known limitations

- **Web build:** tokens are kept in the browser's local storage (the web plugin stores its encryption key next to the data), and GitHub Pages cannot send a Content-Security-Policy header. Use the desktop or mobile app for long-lived tokens, and never the web build on a shared computer.
- With two GitHub accounts, repo detail screens (README, files, commits, issues) read with the first GitHub account, so a private repo that only the second account can see may show an error. Writes are not affected.
- Tokens are not revoked on the provider when you disconnect; revoke them on the host if the device is lost.
- Avatars load automatically from the URL the provider returns, so the host serving them can see your IP address.
- Desktop builds are not signed or notarised yet.

The full list of open items is in [doc/follow-ups.md](doc/follow-ups.md).

## Scope

In scope: the app in this repository and its build and release workflows. Out of scope: vulnerabilities in the Git hosts themselves, in Flutter or in third-party packages (report those upstream), and issues that need a device you have already compromised.

## Audit history

- 2026-10-22: automated security review and a multi-stage source audit of the whole app. No exploitable vulnerability was confirmed. The findings were fixed in the same release train (see the changelog): comment images now load only on tap, all links go through the allow-list, account data is cleared on disconnect, repo actions use the right account's token, and the CI and release hardening above.
