# Git Workflow & Branching Strategy Guide

> **For:** Team Leads, Project Managers, and All Developers  
> **Purpose:** Establish a safe, scalable Git workflow that protects the `main` branch and keeps collaboration smooth as the team grows.

---

## Table of Contents

1. [Core Philosophy](#1-core-philosophy)
2. [Branch Architecture](#2-branch-architecture)
3. [Branching Strategy — How to Name & Create Branches](#3-branching-strategy)
4. [Rules: What Goes Where](#4-rules-what-goes-where)
5. [Day-to-Day Developer Workflow](#5-day-to-day-developer-workflow)
6. [Pull Requests (PRs) — The Gateway to Main](#6-pull-requests)
7. [Merging Strategies](#7-merging-strategies)
8. [Resolving Merge Conflicts](#8-resolving-merge-conflicts)
9. [Common Git Errors & How to Fix Them](#9-common-git-errors--how-to-fix-them)
10. [Project Lead Checklist — Protecting Main](#10-project-lead-checklist--protecting-main)
11. [Branch Protection Rules (GitHub Settings)](#11-branch-protection-rules-github-settings)
12. [Emergency Procedures](#12-emergency-procedures)
13. [Quick Reference Cheatsheet](#13-quick-reference-cheatsheet)

---

## 1. Core Philosophy

- **`main` is always deployable.** It must never contain broken, untested, or half-finished code.
- **No one pushes directly to `main`.** Ever. Not even the lead. All changes go through Pull Requests.
- **Small branches, short-lived.** The longer a branch lives, the harder it is to merge. Keep branches focused on a single task.
- **Every merge is reviewed.** At minimum one other person reviews code before it lands in `main`.
- **Communicate before you code.** If two devs touch the same file, coordinate. Don't let merge conflicts be a surprise.

---

## 2. Branch Architecture

The repo uses a **three-tier branch model**:

```
main
  └── develop
        ├── feature/user-auth
        ├── feature/payment-gateway
        ├── fix/login-bug
        └── chore/update-dependencies
```

| Branch | Purpose | Who Merges Into It | Direct Push Allowed? |
|---|---|---|---|
| `main` | Production-ready code | Only from `develop` via PR | ❌ Never |
| `develop` | Integration branch — all features land here first | Developers via PR | ❌ Never |
| `feature/*` | New features | Created by developer, merged into `develop` | ✅ Only your own branch |
| `fix/*` | Bug fixes | Created by developer, merged into `develop` | ✅ Only your own branch |
| `hotfix/*` | Urgent production fixes | Goes directly into `main` AND `develop` | ✅ Only your own branch |
| `chore/*` | Non-code changes (docs, deps, config) | Merged into `develop` | ✅ Only your own branch |
| `release/*` | Release preparation and version bumps | Merged into `main` then `develop` | ✅ Only by lead |

---

## 3. Branching Strategy

### 3.1 How to Name Your Branch

Follow this naming convention **strictly** so everyone knows what a branch is for at a glance:

```
<type>/<short-description>
```

**Types:**

| Type | Use for |
|---|---|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `hotfix/` | Critical production fixes |
| `chore/` | Maintenance, dependency updates, config |
| `refactor/` | Code restructuring without behavior change |
| `test/` | Adding or fixing tests |
| `docs/` | Documentation only |

**Examples:**

```
feature/user-registration
feature/dashboard-analytics
fix/navbar-mobile-overflow
hotfix/payment-crash-prod
chore/upgrade-react-18
refactor/auth-service-cleanup
docs/api-endpoint-guide
```

**Rules:**
- Use **lowercase** only
- Use **hyphens**, not underscores or spaces
- Keep it **short but descriptive** (3–5 words max)
- Include a **ticket/issue number** if your team uses one: `feature/AUTH-42-user-registration`

### 3.2 Creating a Branch

Always branch off from `develop`, not `main`:

```bash
# Step 1: Switch to develop and pull the latest changes
git checkout develop
git pull origin develop

# Step 2: Create and switch to your new branch
git checkout -b feature/your-feature-name

# Step 3: Verify you're on the right branch
git branch
```

---

## 4. Rules: What Goes Where

### ✅ Allowed

| Action | Who | Target |
|---|---|---|
| Push commits | Any developer | Their own feature/fix branch |
| Open a Pull Request | Any developer | `develop` |
| Review a PR | Any developer (not the author) | — |
| Merge a PR into `develop` | Lead or designated reviewer | `develop` |
| Merge `develop` → `main` | Project Lead only | `main` |
| Create a hotfix | Lead or senior dev | `hotfix/*` |

### ❌ Never Allowed

- Pushing directly to `main`
- Pushing directly to `develop`
- Force-pushing (`git push --force`) to `main` or `develop`
- Merging your own PR without review
- Committing credentials, `.env` files, or secrets

---

## 5. Day-to-Day Developer Workflow

Follow these steps for every task you work on:

### Step 1 — Start fresh from `develop`

```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-task-name
```

### Step 2 — Work in small commits

Commit often. Each commit should represent one logical unit of work:

```bash
git add .
git commit -m "feat: add email validation to registration form"
```

**Commit message format:**

```
<type>: <short description>
```

| Type | Meaning |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `chore` | Maintenance |
| `refactor` | Refactoring |
| `docs` | Documentation |
| `test` | Tests |
| `style` | Formatting only (no logic change) |

**Examples:**
```
feat: add product search with filters
fix: resolve null pointer in user session
chore: update npm packages to latest versions
docs: add README setup instructions
```

### Step 3 — Stay in sync with `develop`

While you're working, `develop` may move forward with others' merges. Sync your branch regularly (at least daily for long-running features):

```bash
git checkout develop
git pull origin develop
git checkout feature/your-task-name
git merge develop
# OR use rebase (see Section 7)
git rebase develop
```

This reduces merge conflict pain later.

### Step 4 — Push your branch

```bash
git push origin feature/your-task-name
```

If this is your first push on this branch:

```bash
git push -u origin feature/your-task-name
```

### Step 5 — Open a Pull Request

Go to GitHub → your repo → "Compare & pull request."

Fill out the PR template (see Section 6).

### Step 6 — Address review feedback

```bash
# Make changes locally, then:
git add .
git commit -m "fix: address PR review comments on validation logic"
git push origin feature/your-task-name
```

The PR updates automatically.

### Step 7 — After merge, clean up

Once your PR is merged:

```bash
# Switch back to develop and pull
git checkout develop
git pull origin develop

# Delete your local branch
git branch -d feature/your-task-name

# Delete the remote branch (GitHub may do this automatically)
git push origin --delete feature/your-task-name
```

---

## 6. Pull Requests

Pull Requests (PRs) are the mandatory gate before any code enters `develop` or `main`. They exist for code review, discussion, and quality control.

### 6.1 Opening a Pull Request

**Before opening a PR, verify:**
- [ ] Your branch is up to date with `develop`
- [ ] All tests pass locally
- [ ] No debug logs, commented-out code, or temporary hacks left in
- [ ] No `.env` files or secrets committed
- [ ] Your code runs without errors on your machine

**When filling out the PR:**

**Title:** Clear and descriptive
```
feat: Add user registration with email verification
fix: Resolve crash on empty cart checkout
```

**Description should include:**
```markdown
## What does this PR do?
Brief explanation of what changed and why.

## How to test it?
Step-by-step instructions for the reviewer to verify it works.

## Screenshots (if UI changed)
Before / After screenshots.

## Related Issue
Closes #42

## Checklist
- [ ] Tested locally
- [ ] No console errors
- [ ] No secrets committed
- [ ] Tests updated/added if needed
```

### 6.2 Reviewing a Pull Request

**As a reviewer:**
- Pull the branch and test it locally if possible
- Look for: logic errors, security issues, performance problems, missing edge cases
- Be specific and constructive in comments — don't just say "this is wrong," explain why and suggest a fix
- Approve only when you're genuinely confident the code is correct

**Review checklist:**
- [ ] Code does what the PR description says
- [ ] No obvious bugs or edge cases missed
- [ ] No hardcoded credentials or sensitive data
- [ ] Follows the team's coding standards
- [ ] Tests exist for new functionality

### 6.3 PR Rules

- **Minimum 1 approval** required before merging (2 recommended for critical areas)
- **Author cannot merge their own PR** — another team member must approve
- **All review comments must be resolved** before merging
- **CI checks must pass** (linting, tests, build) before merging
- PRs should be **small and focused** — one feature or fix per PR, not a dump of 3 weeks of work

---

## 7. Merging Strategies

There are three ways to merge a branch. The team should agree on one strategy and stick with it.

### 7.1 Merge Commit (Recommended for `feature → develop`)

```bash
git checkout develop
git merge feature/your-feature-name
```

Creates a merge commit that preserves the full history of the feature branch. Best for features.

✅ Full history preserved  
✅ Easy to see when features landed  
❌ Can clutter history with lots of tiny commits

### 7.2 Squash and Merge (Recommended via GitHub UI for clean history)

All commits from the feature branch are squashed into one single commit before merging. This keeps `develop`'s history clean.

Use this in GitHub by selecting **"Squash and merge"** in the PR merge dropdown.

✅ Clean, readable history on `develop`  
✅ One commit per feature  
❌ Loses individual commit granularity from the feature branch

**Recommended default** for most teams.

### 7.3 Rebase and Merge

Replays your commits on top of `develop` as if you branched from the latest point.

```bash
git checkout feature/your-feature-name
git rebase develop
git checkout develop
git merge feature/your-feature-name
```

✅ Linear, clean history  
❌ Rewrites commit history — can cause problems if branch is shared with others  
❌ Harder to use correctly

**Use only if your team is experienced with Git.**

### 7.4 Merging `develop` → `main`

Only the project lead does this, and only when `develop` is stable and tested:

```bash
git checkout main
git pull origin main
git merge develop --no-ff -m "release: v1.4.0 — user auth and dashboard features"
git push origin main
git tag -a v1.4.0 -m "Release v1.4.0"
git push origin v1.4.0
```

Always tag releases on `main`.

---

## 8. Resolving Merge Conflicts

Merge conflicts happen when two people edit the same lines in the same file. They are normal — don't panic.

### 8.1 What a Conflict Looks Like

When you merge or rebase and Git hits a conflict, the affected file will look like this:

```
<<<<<<< HEAD (your branch)
const timeout = 5000;
=======
const timeout = 3000;
>>>>>>> develop
```

- Everything between `<<<<<<< HEAD` and `=======` is **your version**
- Everything between `=======` and `>>>>>>>` is **the incoming version** (from `develop`)

### 8.2 How to Resolve Conflicts Step by Step

**Step 1 — Identify conflicted files:**

```bash
git status
# Look for "both modified: filename.js"
```

**Step 2 — Open each conflicted file** in your editor. VS Code highlights conflicts visually with "Accept Current Change / Accept Incoming Change / Accept Both" buttons — use them.

**Step 3 — Edit the file** to the correct final version. Remove all `<<<<<<<`, `=======`, and `>>>>>>>` markers. The resolved file should look exactly how it should in production.

**Step 4 — Stage the resolved file:**

```bash
git add src/config.js
```

**Step 5 — Complete the merge:**

```bash
git commit
# OR if you were rebasing:
git rebase --continue
```

### 8.3 Preventing Conflicts

- **Pull from `develop` every morning** before you start coding
- **Keep branches short-lived** — merge within days, not weeks
- **Communicate with teammates** — if two of you need to edit the same file, coordinate who goes first
- **Break large files into smaller modules** — conflicts are more frequent in large, monolithic files

### 8.4 Aborting a Merge Gone Wrong

If you've made a mess and want to start over:

```bash
# Abort an in-progress merge
git merge --abort

# Abort an in-progress rebase
git rebase --abort
```

---

## 9. Common Git Errors & How to Fix Them

### ❌ "Your local changes would be overwritten by merge"

You have uncommitted changes and tried to switch branches or pull.

**Fix:**
```bash
# Option A: Stash your changes temporarily
git stash
git pull origin develop
git stash pop  # reapply your changes

# Option B: Commit your changes first
git add .
git commit -m "wip: save progress before pulling"
git pull origin develop
```

---

### ❌ "Rejected — non-fast-forward"

Someone else pushed to the remote branch and your local is behind.

**Fix:**
```bash
git pull origin your-branch-name
# Resolve any conflicts if they appear, then push again
git push origin your-branch-name
```

---

### ❌ "Detached HEAD state"

You checked out a commit directly instead of a branch.

**Fix:**
```bash
# Create a new branch from where you are
git checkout -b recovery-branch

# Or go back to a real branch
git checkout develop
```

---

### ❌ "fatal: refusing to merge unrelated histories"

Usually happens when two repos were combined or a branch was created incorrectly.

**Fix:**
```bash
git pull origin develop --allow-unrelated-histories
# Then resolve any conflicts and commit
```

---

### ❌ Committed to the wrong branch

You accidentally committed to `develop` directly (or the wrong feature branch).

**Fix:**
```bash
# Step 1: Note the commit hash
git log --oneline -5

# Step 2: Create a new branch with those commits
git checkout -b feature/correct-branch

# Step 3: Go back to the wrong branch and undo the commit
git checkout develop
git reset HEAD~1  # removes last commit, keeps changes in working directory

# Step 4: Now your changes are back on develop as unstaged. Stash or discard.
git checkout feature/correct-branch
# Your commits are now only on the correct branch
```

---

### ❌ Accidentally committed a secret / `.env` file

**Act immediately:**

```bash
# Remove the file from tracking (add to .gitignore first)
echo ".env" >> .gitignore
git rm --cached .env
git add .gitignore
git commit -m "chore: remove .env from tracking"
git push
```

**If it was already pushed:** The secret is compromised. Rotate/revoke the credential immediately. Then use `git filter-branch` or BFG Repo Cleaner to scrub history (contact your lead).

---

### ❌ "Merge conflict in package-lock.json / yarn.lock"

**Fix:**
```bash
# Accept one version of the lockfile (usually incoming/develop)
git checkout --theirs package-lock.json
npm install  # regenerate it properly
git add package-lock.json
git commit -m "fix: regenerate package-lock after merge conflict"
```

---

### ❌ Need to undo the last commit (not yet pushed)

```bash
# Keep changes in working directory (safe)
git reset HEAD~1

# Discard changes entirely (destructive — use carefully)
git reset --hard HEAD~1
```

---

### ❌ Need to undo a commit that was already pushed

```bash
# Create a new commit that reverses the bad one (safe — doesn't rewrite history)
git revert <commit-hash>
git push origin your-branch
```

Never use `git reset --hard` on pushed commits that others might have pulled.

---

## 10. Project Lead Checklist — Protecting Main

This section is specifically for the **project owner/lead**. Follow these practices to ensure `main` never breaks and code is never lost.

### 10.1 One-Time GitHub Repository Setup

Do this immediately for your repo if not already done:

**Enable Branch Protection on `main`:**
1. GitHub → Repo → Settings → Branches → Add branch protection rule
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (set to at least 1, ideally 2)
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Require status checks to pass before merging (CI/CD)
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators (apply rules to yourself too)
   - ✅ Restrict who can push to matching branches (only you)

**Repeat for `develop` branch:**
- Same rules, but you can allow the team lead to merge approved PRs

### 10.2 Before Every Sprint / Milestone

- [ ] Ensure `develop` is stable and all open PRs are reviewed/merged or deferred
- [ ] Pull `develop` locally and run the full test suite
- [ ] Confirm `develop` builds successfully
- [ ] Check `git log --oneline develop` to verify the expected commits are present
- [ ] Brief the team on which files/modules each developer owns this sprint to preempt conflicts

### 10.3 Before Merging `develop` → `main`

- [ ] All planned features for this release are merged into `develop`
- [ ] Full test suite passes on `develop`
- [ ] Manual QA/smoke testing done on `develop`
- [ ] No open PRs targeted at this release are still pending
- [ ] Create a `release/v1.x.x` branch from `develop` if doing formal releases
- [ ] Update changelog / version number
- [ ] Get at least one other senior developer to review the final state of `develop`

```bash
# Merge checklist commands
git checkout develop
git pull origin develop
git log --oneline main..develop  # See exactly what's new since last main merge
```

### 10.4 Backup Strategy

**GitHub is not a backup.** Use these additional protections:

1. **Enable GitHub repository backup** — use a service like Backrightup or Rewind, or set up a cron job that mirrors the repo:
   ```bash
   git clone --mirror https://github.com/yourorg/yourrepo.git
   ```

2. **Tag every release** on `main`:
   ```bash
   git tag -a v1.3.0 -m "Release v1.3.0 — April sprint"
   git push origin v1.3.0
   ```
   Tags are permanent markers. Even if branches are accidentally deleted, tags point to the exact commit.

3. **Never delete `main` or `develop`** — set them as protected in GitHub so they cannot be deleted (branch protection rules cover this).

4. **Keep a local clone** of the repo on your machine, separate from your working copy, synced weekly:
   ```bash
   git fetch --all
   git pull origin main
   ```

### 10.5 Weekly Lead Responsibilities

- [ ] Review all open PRs — chase stale ones, close PRs that are no longer relevant
- [ ] Delete merged branches (GitHub can auto-delete, enable in repo Settings → General → "Automatically delete head branches")
- [ ] Run `git log --oneline main` and compare with your release notes to verify what shipped
- [ ] Check `develop` is not dramatically ahead of or behind `main` (if it is, schedule a release)
- [ ] Review any dependabot/security alerts in the GitHub Security tab
- [ ] Ensure no developer is working directly on `develop` — remind the team of the workflow if needed

### 10.6 Onboarding New Developers

Every new developer must:
1. Read this document before writing their first line of code
2. Have their GitHub account added with **Write** access (not Admin)
3. Never be given Admin access unless they are a designated lead
4. Submit their first PR to `develop` for a simple task (e.g., add their name to a CONTRIBUTORS file) so they practice the workflow with low stakes

---

## 11. Branch Protection Rules (GitHub Settings)

Summary of the recommended GitHub settings:

| Setting | `main` | `develop` |
|---|---|---|
| Require PR before merging | ✅ | ✅ |
| Required approvals | 2 | 1 |
| Dismiss stale approvals | ✅ | ✅ |
| Require status checks | ✅ | ✅ |
| Require branches up to date | ✅ | ✅ |
| No direct pushes | ✅ | ✅ |
| Restrict who can merge | Lead only | Lead + seniors |
| Allow force pushes | ❌ | ❌ |
| Allow deletions | ❌ | ❌ |

---

## 12. Emergency Procedures

### Production is broken — Hotfix needed NOW

```bash
# Step 1: Branch off main (not develop — main is prod)
git checkout main
git pull origin main
git checkout -b hotfix/critical-payment-crash

# Step 2: Fix the issue, commit
git add .
git commit -m "hotfix: fix null reference crash in payment processor"

# Step 3: Push and open a PR to main (emergency — expedited review)
git push origin hotfix/critical-payment-crash
# Open PR → main, get ONE quick approval, merge

# Step 4: IMMEDIATELY also merge into develop so the fix isn't lost
git checkout develop
git merge hotfix/critical-payment-crash
git push origin develop

# Step 5: Tag the hotfix release
git checkout main
git pull origin main
git tag -a v1.3.1 -m "Hotfix: payment crash"
git push origin v1.3.1

# Step 6: Clean up
git branch -d hotfix/critical-payment-crash
git push origin --delete hotfix/critical-payment-crash
```

### Someone force-pushed and history is broken

```bash
# Find the last good commit
git reflog  # Shows all recent HEAD changes including force-pushes

# Restore main to the correct commit
git checkout main
git reset --hard <last-good-commit-hash>
git push --force-with-lease origin main  # Only the lead can do this
```

### Accidentally deleted a branch

```bash
# Find the lost commit hash from reflog
git reflog

# Recreate the branch from that commit
git checkout -b recovered-branch <commit-hash>
git push origin recovered-branch
```

---

## 13. Quick Reference Cheatsheet

```bash
# ── START A NEW TASK ──────────────────────────────────────────
git checkout develop && git pull origin develop
git checkout -b feature/your-task-name

# ── DAILY SYNC (keep up with develop) ────────────────────────
git checkout develop && git pull origin develop
git checkout feature/your-task-name
git merge develop

# ── COMMIT ────────────────────────────────────────────────────
git add .
git commit -m "feat: describe what you did"
git push origin feature/your-task-name

# ── AFTER YOUR PR IS MERGED ───────────────────────────────────
git checkout develop && git pull origin develop
git branch -d feature/your-task-name
git push origin --delete feature/your-task-name

# ── STASH UNCOMMITTED CHANGES ─────────────────────────────────
git stash          # save temporarily
git stash pop      # bring them back

# ── UNDO LAST COMMIT (not pushed) ─────────────────────────────
git reset HEAD~1

# ── UNDO PUSHED COMMIT (safe) ─────────────────────────────────
git revert <commit-hash>

# ── SEE WHAT'S DIFFERENT ──────────────────────────────────────
git log --oneline -10
git diff develop
git status

# ── TAG A RELEASE ─────────────────────────────────────────────
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

---

> Last updated: June 2026  
> Maintained by: Project Lead  
> Questions? Open an issue on the repo or message the lead directly.
