# Follow-ups

Open work to come back to. Last reviewed: 2026-10-22, after the security hardening in [PR #10](https://github.com/atefelsaeed/RepoSphere/pull/10).

## Before a public launch

- [ ] **Release signing.** The workflow and Gradle already support a release key but nothing has been run with one. Create a keystore, add the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, run the *Release* workflow with and without them, and check the APK with `apksigner verify`. Desktop builds are still unsigned / not notarised.
- [ ] **Application id.** `com.reposphere.app.repo_sphere` is a placeholder. Changing it later breaks updates for anyone who installed the APK, so decide before real users.
- [ ] **Try real accounts.** Tests use mocked API responses and demo data only.

## Security leftovers

- [ ] Remove `supabase_flutter` (and `supabase_provider`, `supabase_auth_service`, the auth screen wiring) if the optional Supabase sign-in is not going to be used. It is unconfigured today but still in every build.
- [ ] Web build keeps tokens in browser local storage. Say so on the connect screen, not only in the README and FAQ.
- [ ] Sentry (opt-in): HTTP breadcrumbs are dropped; review other event data (screen names, exception messages) before turning it on for real users.

## Quality

- [ ] CI runs `dart analyze lib/` only. `test/` has a few `curly_braces_in_flow_control_structures` infos; fix them and analyze the whole project.
- [ ] No tests for the repo browser screens or the GitHub datasource actions.
- [ ] 72 packages are behind their latest version; Dependabot will open PRs, review them in batches.
- [ ] `tool/*.py` are one-off migration scripts (l10n); delete or document them.

## Done

- Markdown links limited to http / https / mailto; remote images load on tap; plain `http://` refused for public hosts; Actions pinned to SHAs; read-only default permissions in `release.yml`; Dependabot; optional release signing wiring (see the [CHANGELOG](../CHANGELOG.md)).
