# Follow-ups

Open work to come back to. Last reviewed: 2026-10-22, after the security hardening in [PR #10](https://github.com/atefelsaeed/RepoSphere/pull/10) and the audit follow-ups (see the [changelog](../CHANGELOG.md)).

## Before a public launch

- [ ] **Release signing.** The workflow and Gradle already support a release key but nothing has been run with one. Create a keystore, add the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, run the *Release* workflow (a tagged release now fails without them; a build-only run still uses the debug key), and check the APK with `apksigner verify`. Desktop builds are still unsigned / not notarised.
- [ ] **Application id.** `com.reposphere.app.repo_sphere` is a placeholder. Changing it later breaks updates for anyone who installed the APK, so decide before real users.
- [ ] **Try real accounts.** Tests use mocked API responses and demo data only.

## Security leftovers

- [ ] **Turn on private vulnerability reporting** (repository *Settings → Code security*) so the process in [SECURITY.md](../SECURITY.md) works as written.
- [ ] Repo detail screens (README, files, commits, issues, branches, releases) still read with the *first* GitHub account. Key those providers by `RepoEntity.connectionId` (use `githubDatasourceForConnectionProvider`) so a second GitHub account's private repos work; writes already do.
- [ ] Remove `supabase_flutter` (and `supabase_provider`, `supabase_auth_service`, the auth screen wiring) if the optional Supabase sign-in is not going to be used. It is unconfigured today but still in every build. Its `signedOut` handler also wipes all stored connections, which is another reason to drop it.
- [ ] Web: GitHub Pages cannot send a Content-Security-Policy header; consider a custom domain, a `<meta>` CSP, or session-only tokens on web (the connect screen already warns).
- [ ] Defence in depth: `Uri.encodeComponent` in the Azure and GitLab path builders (GitHub and Gitea are done); `followRedirects: false` on authenticated requests (needs a check that GitHub's legitimate redirects still work); run the instance-URL check in `buildGitProvider` too; size limits on responses.
- [ ] Add build provenance / attestations to releases; Flutter is pinned to 3.41.6, so bump it by hand (Dependabot cannot).
- [ ] Avatars load automatically from provider URLs (the host sees your IP). Route them through one widget that requires `https` and can be switched off.
- [ ] Notifications show private PR titles on the lock screen; offer a "hide content" option.

## Quality

- [ ] CI runs `dart analyze lib/` only. `test/` has a few `curly_braces_in_flow_control_structures` infos; fix them and analyze the whole project.
- [ ] No tests for the repo browser screens or the GitHub datasource actions.
- [ ] 72 packages are behind their latest version; Dependabot will open PRs, review them in batches.
- [ ] `tool/*.py` are one-off migration scripts (l10n); delete or document them.

## Done

- Audit follow-ups: Sentry URL scrubbing, encoded GitHub/Gitea path segments, web token warning, Flutter pinned, tests gate releases and the web deploy; all Markdown through `SafeMarkdown` (comments included), all provider URLs through `openExternalLink`, account data wiped on disconnect, Android backup off, per-account star / create-issue, CI permissions, tag validation, checksums and a refusal to publish a debug-signed APK.
- Markdown links limited to http / https / mailto; remote images load on tap; plain `http://` refused for public hosts; Actions pinned to SHAs; read-only default permissions in `release.yml`; Dependabot; optional release signing wiring (see the [CHANGELOG](../CHANGELOG.md)).
