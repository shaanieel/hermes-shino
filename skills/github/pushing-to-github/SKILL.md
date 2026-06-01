---
name: pushing-to-github
description: "Push existing projects to GitHub — init, build artifacts, secret scanning, ownership fixes."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [GitHub, Git, Push, Secrets, build-artifacts, push-protection]
    related_skills: [github-auth, github-repo-management, github-pr-workflow]
---

# Pushing an Existing Project to GitHub

When you need to git-init an existing directory and push it as a new GitHub repo. Covers common pitfalls with build artifacts, secret scanning, and npm global install permissions.

## 1. Pre-Flight: Identify Build Artifacts

Before `git init`, scan for build output directories that should NOT be committed. These often contain bundled credentials, OAuth client IDs, API keys, and other push-blocking secrets:

```bash
# Common build artifact directories to exclude
ls -d .next-cli-build/ .next/ dist/ build/ out/ target/ __pycache__/ .build-home/ 2>/dev/null
```

**Critical for Next.js projects installed via npm:** the `app/.next-cli-build/` directory contains compiled server/client bundles with embedded OAuth credentials from the build-time environment. These WILL trigger GitHub push protection.

## 2. Initialize with .gitignore First

```bash
# Create .gitignore BEFORE git add
cat > .gitignore << 'EOF'
node_modules/
.next-cli-build/
.next/
.build-home/
dist/
build/
*.log
.env
*.sqlite
*.sqlite-wal
*.sqlite-shm
EOF

git init -b main
git add -A
git status --short | wc -l  # Sanity check file count
git commit -m "Initial commit"
```

## 3. Permission Fixes for npm Global Installs

When the project lives under `/usr/lib/node_modules/` (owned by root):

```bash
# Fix ownership so git works without sudo
sudo chown -R $(whoami):$(whoami) /usr/lib/node_modules/PROJECT_NAME

# If already init'd as root, fix .git too
sudo chown -R $(whoami):$(whoami) /usr/lib/node_modules/PROJECT_NAME/.git

# Register as safe directory (for dubious ownership error)
git config --global --add safe.directory /usr/lib/node_modules/PROJECT_NAME
```

## 4. GitHub Push Protection: Secrets in History

**Problem:** You `git add`ed a build directory (like `.next-cli-build/`), committed, then `git rm --cached` it in a second commit. Push is STILL blocked because GitHub scan checks ALL commits in the push, not just HEAD.

**Wrong approach:**
```bash
git rm -r --cached app/.next-cli-build
git commit -m "Remove build artifacts"
git push  # STILL FAILS — first commit has the secrets
```

**Right approach — squash history to eliminate the bad commit entirely:**

```bash
# Option A: Soft reset to root, recommit without artifacts
git rm -r --cached app/.next-cli-build app/cli/.build-home 2>/dev/null
git reset --soft $(git rev-list --max-parents=0 HEAD)
git commit -m "Initial commit"

# Option B: If reflog keeps old commits alive, do a clean re-init
rm -rf .git
git init -b main
# ... git add, commit, push fresh
```

Then force-push:
```bash
git push --force -u origin main
```

**Why this works:** The old commit with secrets no longer exists in the push history. GitHub push protection scans the entire push — if no commit in the pushed DAG contains the secret, it passes.

## 5. Multiple GitHub Accounts on One Machine

When SSH key belongs to account A (e.g., a bot), but you need to push to account B:

```bash
# SSH-based push uses the SSH key identity — may be wrong account
ssh -T git@github.com  # See which account the key authenticates as

# Use HTTPS + PAT instead for explicit account targeting
TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | cut -d= -f2 | tr -d '\n\r ')
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/OWNER/REPO.git"
git push -u origin main
```

The `x-access-token` username tells GitHub to use the PAT for auth rather than SSH.

## 6. Full Push Checklist

- [ ] `.gitignore` created with build artifact patterns
- [ ] Build directories NOT staged (`git status` sanity check)
- [ ] No `.env`, `.sqlite`, or credential files in staging
- [ ] Ownership fixed (no `sudo` needed for git ops)
- [ ] `git config --global --add safe.directory` set if needed
- [ ] Remote URL uses correct auth method (SSH vs HTTPS+PAT)
- [ ] Commit message is clean (no `--fixup` or WIP commits)

## Quick Recipe: npm Global Project to GitHub

```bash
# 1. Fix perms
sudo chown -R $(whoami):$(whoami) /usr/lib/node_modules/PROJECT_NAME
git config --global --add safe.directory /usr/lib/node_modules/PROJECT_NAME

# 2. Prep
cd /usr/lib/node_modules/PROJECT_NAME
cat > .gitignore << 'EOF'
node_modules/
.next-cli-build/
.build-home/
*.log
.env
*.sqlite*
EOF

# 3. Init and commit
git init -b main
git add -A
git commit -m "Initial commit: PROJECT vVERSION - DESCRIPTION"

# 4. Create repo + push
gh repo create OWNER/PROJECT --public --source=. --remote=origin --push

# If push fails with secret scanning, squash:
git rm -r --cached dir/with/secrets 2>/dev/null
git reset --soft $(git rev-list --max-parents=0 HEAD)
git commit -m "Initial commit: PROJECT vVERSION"
git push --force -u origin main
```
