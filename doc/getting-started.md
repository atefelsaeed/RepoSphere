# Getting started

This guide takes you from "nothing installed" to "my first Inbox", in about five minutes.

## 1. Get the app

Pick whatever is easiest. All downloads are on the [latest release](https://github.com/atefelsaeed/RepoSphere/releases/latest).

| Where | How |
|---|---|
| **In the browser** | Open the [live demo](https://atefelsaeed.github.io/RepoSphere/). Nothing to install. |
| **macOS** | Download `RepoSphere-macos.zip`, unzip, then **right-click `RepoSphere.app` → Open** the first time (the app is not notarised, so a plain double-click is blocked by Gatekeeper). |
| **Windows** | Download `RepoSphere-windows-x64.zip`, unzip, run `repo_sphere.exe`. If SmartScreen warns, choose *More info → Run anyway*. |
| **Linux** | Download `RepoSphere-linux-x64.tar.gz`, extract, run `./repo_sphere`. You need GTK 3 and `libsecret`, plus a running secret service (GNOME Keyring or KWallet) so the app can store your tokens. |
| **Android** | Download `RepoSphere-android.apk` and install it (allow "install unknown apps" for your browser/files app). It is signed with a debug key, so it is for testing, not the Play Store. |
| **iOS** | Build from source with Xcode (see [Building from source](#building-from-source)). There is no App Store build yet. |

## 2. Create a token

RepoSphere signs in to your Git hosts with a **Personal Access Token** (PAT): a password-like string you create on the host, limited to the permissions you choose. It never leaves your device except to talk to that host.

Create one for each host you use, then paste it into the app. The in-app form has a **"Create a token on …"** button that opens the right page for you.

### GitHub
1. Open <https://github.com/settings/tokens/new> (classic token).
2. Name it `RepoSphere`, pick an expiry, and tick: **`repo`**, **`read:user`**, **`notifications`**, **`gist`**.
3. Generate and copy the token (it starts with `ghp_`).

`repo` also covers approving, merging and re-running CI. For organisations that enforce SAML SSO, click *Configure SSO → Authorize* next to the token.

### GitLab (gitlab.com or self-hosted)
1. Open *Preferences → Access tokens* on your GitLab (for gitlab.com: <https://gitlab.com/-/user_settings/personal_access_tokens>).
2. Add a token with scopes **`api`** and **`read_user`**.
3. Copy it (starts with `glpat-`).

For a **self-hosted** GitLab you will also type your instance URL, for example `https://gitlab.example.com`.

### Azure DevOps
1. Open `https://dev.azure.com/<your-org>/_usersSettings/tokens`.
2. *New Token*. Give **Code (Read)** and **Work Items (Read)**. To approve, request changes and merge from the app, give **Code (Read & write)** instead.
3. Copy the token. You will also enter your organisation URL, for example `https://dev.azure.com/your-org`.

### Forgejo / Gitea (Codeberg or your own server)
1. Open `<your-server>/user/settings/applications` (for Codeberg: <https://codeberg.org/user/settings/applications>).
2. Generate a token with **`read:user`**, **`read:repository`**, **`write:repository`**, **`write:issue`**.
3. Copy it. You will also enter the server URL, for example `https://codeberg.org`.

> **Tip:** use the least-privileged token that works for you, give it an expiry, and revoke it on the host when you stop using the app. You can use the app read-only by omitting the write scopes; actions that need them will then fail with a clear error.

## 3. Connect your account

1. Open the app. On first launch you land on the login screen. (Later: **Settings → Add account**.)
2. Choose your provider: **GitHub, GitLab, Azure DevOps or Gitea / Forgejo**.
3. For GitLab (self-hosted), Azure DevOps and Gitea / Forgejo, fill in the URL.
4. Paste the token and press **Connect**. The app checks it before saving and tells you if it is wrong.

You can connect as many accounts as you like, on any mix of providers, including two accounts on the same host.

## 4. Your first Inbox

After connecting you land on the **Inbox**: everything that needs you, most urgent first. Open the [user guide](user-guide.md) to learn what each label means and what you can do from here.

---

## Building from source

You need [Flutter](https://docs.flutter.dev/get-started/install) **3.41 or newer**.

```bash
git clone https://github.com/atefelsaeed/RepoSphere.git
cd RepoSphere
flutter pub get
flutter run -d chrome        # or: -d macos | windows | linux | <simulator or device id>
```

Useful commands:

```bash
flutter test                                  # unit and widget tests
flutter analyze                               # static analysis
flutter build web --release                   # production web build
flutter build macos --release                 # also: windows, linux, apk, ios
```

Linux builds need: `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libjsoncpp-dev libcurl4-openssl-dev`.

More in [CONTRIBUTING.md](../CONTRIBUTING.md).
