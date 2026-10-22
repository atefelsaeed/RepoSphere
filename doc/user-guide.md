# User guide

RepoSphere answers one question: **"what needs me today?"**, across all your Git accounts at once.

## The Inbox

The home screen lists pull / merge requests and issues from every connected account, merged into one list and **sorted by urgency**. If the same PR matches several rules it shows once, with every reason.

### What the labels mean

From most to least urgent:

| Label | Meaning |
|---|---|
| **CI failed** | One of *your* open PRs has a failing check or pipeline. |
| **Changes requested** | A reviewer asked for changes on *your* PR. |
| **Merge conflicts** | *Your* PR can't be merged until you resolve conflicts. |
| **Review requested** | You were asked to review someone's PR. |
| **Assigned to you** | A PR or issue is assigned to you. |
| **Mentioned** | You were @-mentioned. |

### Filters

- **Workspace / account chips** (top row): show one client or account at a time. See [Workspaces](#workspaces).
- **Reason chips** (second row): narrow to e.g. only *CI failed*. Each chip shows how many items it has.

### Refreshing

Pull down to refresh. The Inbox also **opens instantly** from the last saved snapshot while it refreshes in the background. If one account can't be loaded (expired token, offline, rate limit) a banner names it and says why, instead of silently showing a shorter list. A red banner saying *"Some results … may be missing"* means a query failed while others worked.

### Clearing items

- **Swipe right → Done.** The item disappears until it gets *new activity* (a new commit, comment, review…), then it comes back.
- **Swipe left → Snooze** for 4 hours, until tomorrow, or next week.
- Tapped by mistake? The **Undo** button appears for a few seconds after marking done.

## Open an item

Tap an item to read it without leaving the app:

- the **description** (Markdown rendered),
- the **branches** (`feature → main`),
- **Files changed** with a coloured diff (tap a file to expand it),
- the **discussion**.

For Azure DevOps the changed files are listed without line-by-line hunks (its API doesn't provide them); use *Open in browser* for the full diff.

## Act on an item

Press **Actions** at the bottom of the item (or **long-press** an item in the Inbox) to:

| Action | What it does |
|---|---|
| **Re-run failed CI** | Restarts failed workflow runs (GitHub) or retries the pipeline (GitLab). |
| **Approve** | Approves the PR. You confirm first. |
| **Request changes** | Asks for a comment, then requests changes. |
| **Merge** | Merges the PR. You confirm first. |
| **Open in browser** | Opens the item on the host. |

Only the actions your provider supports are shown. Support differs per provider; see the [table in the README](../README.md#supported-providers).

## Workspaces

A **workspace** groups accounts (or just *part* of an account) under a client name and colour, so you can look at one client at a time.

Open **Workspaces** from the briefcase icon in the Inbox, then **New workspace**:

1. Give it a name and a colour.
2. Add one or more rules. Each rule is an **account**, optionally narrowed to an **org / group**:
   - *Account only* → everything from that account belongs to the workspace.
   - *Account + org* (e.g. `GitHub · maya` + `acme-corp`) → only repos under `acme-corp/`.
   - The form suggests orgs it has already seen in your Inbox: tap one to fill it in.

Rules of thumb:

- A **specific org rule beats an account-wide rule**, so you can put your personal account in "Personal" and `acme-corp` (same GitHub login) in "Acme".
- Items that match no workspace appear under **Unassigned**.
- Workspaces are stored **on this device only**.

## Mobile alerts

*Settings → Urgent inbox alerts* (Android and iOS). When on, the app checks in the background about every 30 minutes and notifies you only about items that **newly** became urgent: *CI failed, changes requested, conflicts, review requested*. Assignments and mentions never notify.

- The first time you turn it on, existing items are recorded silently so you don't get a flood.
- **Check now** runs the check immediately: use it to verify your setup.
- Android runs the check roughly on schedule. **iOS decides when background work runs** and may do it much less often.
- You'll be asked for notification permission when you turn it on.

## Language and theme

*Settings → Language*: **System default**, **English** or **العربية** (right-to-left layout). *Settings → Theme*: system, light or dark.

## Repository browser

The folder icon in the Inbox opens the older repository browser: repos from all your accounts in one list (filter, sort, search, pin), file tree with syntax highlighting, commits and diffs, PRs, issues, releases, and for GitHub also activity, notifications, gists and search. Keyboard shortcuts on that screen: `/` search, `R` refresh, `?` help, `Esc` back.

## Managing accounts

*Settings → Connected Accounts* lists every account. **Add account** connects another; the bin icon removes one (and its token) from this device. Nothing is deleted on the Git host.

## Privacy in one paragraph

Your tokens are stored in the platform's secure store on **your** device and are only ever sent to the Git host they belong to. There is no RepoSphere server. Details in the [FAQ](faq.md#privacy-and-security).
