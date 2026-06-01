---
name: github-workflow-pitfalls
description: "Common GitHub push/auth/PR pitfalls and their proven resolutions."
version: 1.0.0
author: Hermes Agent
---

# GitHub Workflow Pitfalls

Common GitHub workflow issues encountered in practice and how to resolve them.

## Push Protection: Secret Scanning Block

**Problem:** `git push` blocked with `GH013: Repository rule violations found` — GitHub's push protection detected secrets (API keys, OAuth client IDs/secrets, tokens) in one or more commits.

**Key insight:** GitHub scans ALL commits in the push, not just the HEAD. Adding a new commit that removes the problematic files is NOT enough — the secret still exists in the earlier commit and will be flagged.

**Solution: Squash away the offending commits from history.**

### Step 1: Identify what's triggering it
The error message tells you exactly which secrets and which files:
```
remote:       —— Google OAuth Client ID ————————————————————————————
remote:        locations:
remote:          - commit: abc123
remote:            path: app/.next-cli-build/server/chunks/5412.js:1
```

### Step 2: Remove files + squash history

```bash
# Option A: If you already have a follow-up commit removing the files,
# soft reset to the parent of the first problematic commit
git reset --soft <first-bad-commit>~1
git rm -r --cached <path-to-bad-files>
git add <updated .gitignore>
git commit -m "clean commit message"

# Option B: If the bad files are still in the working tree,
# amend or interactive rebase to remove them from history entirely
git reset --soft HEAD~N   # go back N commits
git rm -r --cached <bad-dir>
echo "<bad-dir>/" >> .gitignore
git add .gitignore
git commit -m "fresh commit without secrets"
```

### Step 3: Force push
```bash
git push --force -u origin main
```

If the force push still triggers the scan on old objects, do a full re-init:
```bash
rm -rf .git
git init -b main
git config user.name "..."
git config user.email "..."
git add -A
git commit -m "..."
git remote add origin <url>
git push --force -u origin main
```

### Common culprits
- `app/.next-cli-build/` — Next.js build output containing OAuth secrets baked into JavaScript bundles
- `.env` files accidentally committed
- `config/settings.json` with hardcoded credentials
- Any build artifact directory (`.next/`, `dist/`, `build/`) that may contain bundled secrets

### Prevention
- Add build artifact directories to `.gitignore` BEFORE the first commit
- Use environment variables or secret managers instead of hardcoded credentials
- Run `git diff --cached` before every commit to review what's being staged

## gh CLI Auth from Headless/SSH

**Problem:** No browser available to complete `gh auth login` interactive flow.

**Solution:** Pipe the token directly:
```bash
# Get token from Hermes .env
TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | cut -d= -f2 | tr -d '\n\r ')
echo "$TOKEN" | gh auth login --with-token

# Verify
gh auth status
```

This works on any headless VPS/SSH session. The token needs `repo`, `workflow`, and `read:org` scopes for full functionality.
