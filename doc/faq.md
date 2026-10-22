# FAQ and troubleshooting

## Privacy and security

**Where are my tokens stored?**
On your device, in the platform's secure store: Keychain (iOS, macOS), Keystore-backed storage (Android), Credential Manager (Windows), the system secret service (Linux). On the **web build** they live in the browser's local storage for that site, which is weaker: prefer the desktop or mobile apps for long-lived tokens, and never use the web build on a shared computer.

**Is there a RepoSphere server? Does anyone else see my code or tokens?**
No server. The app talks **directly** to GitHub, GitLab, Azure DevOps or your Forgejo / Gitea server. Nothing is proxied or collected. Crash reporting (Sentry) is **off** unless you build the app yourself with a `SENTRY_DSN`.

**Can I connect a self-hosted server over plain `http://`?**
Only on `localhost` or a private network (10.x, 172.16-31.x, 192.168.x, `*.local`). For any other host the app refuses `http://`, because your token would cross the internet unencrypted. Use `https://`.

**Why do images in a PR or issue show a "Load image" button?**
Images in text written by other people are not fetched automatically: the host serving the image would learn your IP address and when you looked. Tap the button to load one.

**What happens when I tap a link inside a PR, issue or README?**
Only `http`, `https` and `mailto` links open. Other kinds (`tel:`, `file:`, app-specific links) are ignored.

**What else is saved locally?**
Your workspaces, the items you marked done or snoozed, the last Inbox snapshot (so the app opens instantly), and your theme and language choice. None of it is synced anywhere.

**How do I remove everything?**
*Settings → Connected Accounts → bin icon* removes an account and its token. Uninstalling the app removes the rest. Revoke the token on the Git host too if you want it dead everywhere.

**Which permissions does the token need?**
See [Getting started → Create a token](getting-started.md#2-create-a-token). Read-only tokens work for reading; approving/merging/re-running CI needs the write scopes listed there.

## Using the app

**The Inbox is empty, but I have open PRs.**
The Inbox shows only things that need *you*: PRs awaiting your review, assigned to you, mentioning you, or *your own* PRs with failing CI / requested changes / conflicts. A healthy PR you opened is not listed. Check the filter chips aren't narrowing it, and that **Done**/**Snoozed** items aren't hiding it (they return on new activity or when the snooze ends).

**One account is missing from the Inbox.**
Look for the banner at the top: it names the account and the reason (invalid or expired token, rate limit, network). Reconnect the account in *Settings* if the token expired.

**"Some results may be missing."**
At least one query for that account failed while others worked (often a rate limit). Pull to refresh; if it persists the banner says why.

**I get "rate limiting requests".**
GitHub limits how fast the search API can be called. Wait the number of seconds shown and refresh. Fewer connected GitHub accounts refreshing at once helps.

**Approve / Merge says "forbidden" or "not found".**
Your token is missing a write scope, or you don't have permission on that repo, or branch protection requires something else (e.g. required reviews or passing checks). Open the item in the browser to see the host's own message.

**Why does Azure DevOps show no mentions or CI status?**
Azure DevOps has no simple API for either. The Inbox for Azure covers review requests, your PRs with rejections/conflicts, and assigned work items. See the [provider table](../README.md#supported-providers).

**GitLab: why no "Request changes"?**
GitLab's REST API has no such call. You can still approve, merge and re-run the pipeline.

**I don't get notifications on iPhone.**
iOS decides when background work may run, sometimes hours apart or not at all. Open **Settings → Urgent inbox alerts → Check now** to test. Make sure notifications are allowed for the app, Low Power Mode is off, and Background App Refresh is on. After updating the app, open it once so it can finish a one-time keychain update that lets background checks read your tokens while the phone is locked.

**I don't get notifications on Android.**
Allow notifications for the app and exclude it from aggressive battery optimisation (some vendors kill background work). Android runs the check about every 30 minutes.

**The app is in English, I want Arabic (or the reverse).**
*Settings → Language*. "System default" follows your device language.

## Installing

**macOS says the app "can't be opened because it is from an unidentified developer".**
Right-click `RepoSphere.app` → **Open** → **Open** again. The build isn't notarised yet (that needs a paid Apple Developer account).

**Windows SmartScreen blocks it.**
*More info → Run anyway*. The build isn't code-signed yet.

**Linux: the app starts but can't save my token.**
It needs `libsecret` and a running secret service (GNOME Keyring or KWallet). On minimal desktops, install and start one, then try again.

**The Android APK won't install.**
Allow "install unknown apps" for the app you opened it from. Until a release key is configured (see [follow-ups](follow-ups.md)) it is signed with a debug key, so you can't update over a Play Store version.

**Web: connecting my self-hosted GitLab fails.**
The browser only lets the site call servers that allow cross-origin requests (CORS). GitHub, GitLab.com and Azure DevOps do. Your own server may not: use the desktop or mobile app instead, or enable CORS for the web origin on your server.

## Project

**What does it cost?** Nothing. It is open source under the [MIT license](../LICENSE).

**Which providers are supported?** GitHub, GitLab (including self-hosted), Azure DevOps, Forgejo / Gitea (including Codeberg). Bitbucket is planned.

**Something is wrong / I want a feature.** Please [open an issue](https://github.com/atefelsaeed/RepoSphere/issues). Remove tokens and private repo names from anything you paste. For security problems use GitHub's *Report a vulnerability* instead of a public issue.
