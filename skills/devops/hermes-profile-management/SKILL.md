---
name: hermes-profile-management
description: Manage multiple Hermes profiles — create specialized agents, install external GitHub skill repos across profiles, run independent gateway instances, and keep skills/config in sync.
version: 1.0.0
author: agent
metadata:
  hermes:
    tags: [hermes, profiles, multi-agent, skills, gateway, devops]
    related_skills: [hermes-agent]
---

# Hermes Profile Management

Multi-profile Hermes setups: creating specialized agents (designer, reviewer, etc.), installing external GitHub skills across profiles, running independent gateway instances, and keeping everything in sync.

## When to Use

- Setting up multiple specialized Hermes bots on different gateway platforms
- Installing an external GitHub skill repo that contains multiple sub-skills
- Keeping skills, config, and personality (SOUL.md) in sync across profiles
- Managing multiple `hermes -p <profile> gateway run` processes

## Installing External GitHub Skills with Sub-Skills

Some repos (like [taste-skill](https://github.com/Leonxlnx/taste-skill)) bundle multiple sub-skills under a `skills/` directory. Hermes skill auto-discovery does NOT handle nested directories — each skill needs its own top-level directory named after the `name:` field from its SKILL.md frontmatter.

### Procedure

1. **Clone the repo:**
   ```bash
   git clone --depth 1 <repo-url> /tmp/<repo-name>
   ```

2. **Discover all sub-skills:**
   ```bash
   ls /tmp/<repo-name>/skills/
   ```

3. **Extract `name:` from each SKILL.md's frontmatter** (this is the canonical skill name):
   ```bash
   for dir in /tmp/<repo-name>/skills/*/; do
     name=$(head -5 "$dir/SKILL.md" | grep '^name:' | sed 's/name: *//')
     echo "$dir → $name"
   done
   ```

4. **Copy to root skills directory** using the frontmatter `name:` as the directory name:
   ```bash
   cp -r /tmp/<repo-name>/skills/<folder-name> ~/.hermes/skills/<canonical-name>
   ```

5. **Sync to ALL profiles** that need the skill:
   ```bash
   for profile in designer reviewer; do
     cp -r ~/.hermes/skills/<canonical-name> ~/.hermes/profiles/$profile/skills/<canonical-name>
   done
   ```

### Pitfalls

- **DO NOT use nested directories** like `~/.hermes/skills/taste/design-taste-frontend/` — skill loader won't find it.
- **DO NOT use the GitHub folder name** as the directory name — it may differ from the `name:` field in frontmatter (e.g., `soft-skill/` → `name: high-end-visual-design`).
- **Always copy to BOTH** the default profile (`~/.hermes/skills/`) AND each target profile (`~/.hermes/profiles/<name>/skills/`).
- After installing, update the profile's SOUL.md to reference the new skills so the agent knows they exist.

#For common repos with non-matching folder names, see `references/taste-skill-mapping.md` for a complete mapping table.

## Verification

```bash
# Check all profiles have the skill
ls -d ~/.hermes/skills/<name> ~/.hermes/profiles/*/skills/<name>
```

## Updating SOUL.md for New Skills

When adding skills to a profile, update `~/.hermes/profiles/<name>/SOUL.md` to:
1. List the new skill names (using the `name:` value from frontmatter)
2. Add hard rules inherited from the skills
3. Include trigger conditions (when to load each skill)

After updating SOUL.md, **restart the profile's gateway** for changes to take effect.

## Running Multiple Gateway Instances

Each profile needs its own gateway process:

```bash
# Main (default profile)
hermes gateway run

# Designer profile
hermes -p designer gateway run

# Reviewer profile
hermes -p reviewer gateway run
```

### Systemd Service Setup (Recommended)

For durable independent bots, each profile should have its own systemd service with `HERMES_HOME` pointing to the profile directory. See `messaging-gateway-setup` skill's `references/multi-profile-systemd-services.md` for full templates, verification commands, and the drain-hang + negative-ID pitfalls.

### Restarting Profile Gateways

```bash
# Find PIDs
ps aux | grep 'hermes.*gateway' | grep python

# Kill specific profile
kill <pid>

# Restart as background (Hermes CLI handles this safely)
hermes -p <profile> gateway run
```

### Health Check

### Quick Gateway Status (Canonical)

`ps aux | grep gateway` is unreliable — processes may have detached or been restarted. Use the canonical command instead:

```bash
hermes gateway list
```

Output shows per-profile status:

```
Gateways:
  ✗ default (current)        — not running      ← DOWN
  ✓ designer                 — PID 3178619       ← OK
  ✓ reviewer                 — PID 3157501       ← OK
```

This is the **single authoritative check**. Run it first before grepping PIDs.

### Systemd User Service Health (Default Profile)

The default profile's gateway is usually managed by a systemd user service:

```bash
systemctl --user status hermes-gateway --no-pager -l
```

Possible states:
- **`active (running)`** — healthy
- **`failed (Result: signal)`** — killed by SIGKILL (OOM, tool-loop watchdog, or systemd timeout). Check journal for cause:

```bash
journalctl --user -u hermes-gateway --since "1 hour ago" --no-pager
```

**Common failure: terminal tool loop.** When a tool call fails repeatedly in the same turn, the loop detector fires, systemd hits TimeoutStopSec, and sends SIGKILL. Restart with:

```bash
systemctl --user restart hermes-gateway
```

Then verify with `hermes gateway list`.

### Running Gateways (Legacy Check)

```bash
ps aux | grep 'hermes.*gateway' | grep python

# Verify specific profile skill count
ls ~/.hermes/profiles/<profile>/skills/ | wc -l
```

### Per-Profile Log Check

Each profile gateway runs as its own PID. Check recent logs:

```bash
journalctl _PID=<pid> --no-pager -n 20
```

Common errors:
- `Forbidden: bot was kicked from the supergroup chat` — bot needs to be re-added to group
- `HTTP 404: No active credentials for provider: X` — credential expired/missing in router
- `tool_failure_warning` with same tool 4+ times — tool loop; kill and restart

## Profile Structure Reference

```
~/.hermes/
├── skills/                    # Default profile skills
├── profiles/
│   ├── designer/
│   │   ├── SOUL.md            # Personality + skill awareness
│   │   ├── skills/            # Profile-specific skills (SYNC with default)
│   │   ├── config.yaml        # Profile config
│   │   └── .env               # Profile env vars (API keys, etc.)
│   └── reviewer/
│       ├── SOUL.md
│       ├── skills/
│       ├── config.yaml
│       └── .env
```

## Credential Pass-Through for Profile Gateways

When profile gateways run as systemd services and need to access external credentials (GitHub tokens, API keys, etc.), the `.env` file and `env_passthrough` in `config.yaml` are **NOT sufficient** for terminal subprocesses. Hermes may not forward profile `.env` variables to child shells spawned by the terminal tool.

### The Reliable Pattern: Systemd Environment Injection

Inject credentials directly into the systemd service file's `Environment=` directives. For GitHub specifically, three variables are needed:

```
Environment="GITHUB_TOKEN=gho_..."
Environment="GH_TOKEN=gho_..."
Environment="HOME=/home/ubuntu"
```

**Why `HOME` is critical:** Without `HOME` pointing to the real user home, `gh` CLI cannot find `~/.config/gh/hosts.yml` and falls back to `GH_TOKEN`/`GITHUB_TOKEN` env vars. Both paths should be available.

### Full Procedure

1. **Read the current service file:**
   ```bash
   cat ~/.config/systemd/user/hermes-<profile>.service
   ```

2. **Add environment lines after `HERMES_HOME`:**
   ```ini
   Environment="HERMES_HOME=/home/ubuntu/.hermes/profiles/<name>"
   Environment="GITHUB_TOKEN=<token>"
   Environment="GH_TOKEN=<token>"
   Environment="HOME=/home/ubuntu"
   ```

3. **Reload and restart:**
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart hermes-<profile>.service
   ```

4. **Verify env is in the running process:**
   ```bash
   PID=$(systemctl --user show hermes-<profile>.service -p MainPID --value)
   cat /proc/$PID/environ | tr '\0' '\n' | grep -E "GITHUB|GH_TOKEN|HOME"
   ```

### Debugging Path (Why This Is Needed)

When a profile bot reports "not logged into GitHub" despite the main profile having `gh auth status` working:

1. Check `.env` — uncomment/set `GITHUB_TOKEN` + `GH_TOKEN` → often still fails
2. Add `env_passthrough: [GITHUB_TOKEN, GH_TOKEN, HOME]` in `config.yaml` → may still fail
3. Inject `Environment=` lines into systemd service + `daemon-reload` + restart → **this works for env vars**
4. **Symlink `~/.config/gh` and `~/.gitconfig` into `<profile>/home/`** — Hermes sometimes remaps `HOME` to `<profile>/home/` rather than the profile root, so `gh` looks for config at `<profile>/home/.config/gh/hosts.yml` which doesn't exist

The `.env` and `env_passthrough` fixes are useful as defense-in-depth but the combination of systemd injection + profile-home symlinks is what actually makes `gh auth status` succeed from within the bot's terminal session.

### The `HOME` Remap Fix

Hermes may override `HOME` to `<profile>/home/` when spawning terminal subprocesses. To make `gh` CLI and `git` work:

```bash
# For each profile that needs GitHub access:
mkdir -p ~/.hermes/profiles/<name>/home/.config
ln -sfn /home/ubuntu/.config/gh ~/.hermes/profiles/<name>/home/.config/gh
ln -sfn /home/ubuntu/.gitconfig ~/.hermes/profiles/<name>/home/.gitconfig
```

Verify:
```bash
HOME=/home/ubuntu/.hermes/profiles/<name>/home gh auth status
HOME=/home/ubuntu/.hermes/profiles/<name>/home git config user.name
```

### Per-Profile Env Verification

```bash
# Check .env
grep "^GITHUB_TOKEN=\|^GH_TOKEN=" ~/.hermes/profiles/<name>/.env

# Check config.yaml
grep "env_passthrough" ~/.hermes/profiles/<name>/config.yaml

# Check systemd service
grep "GITHUB_TOKEN\|GH_TOKEN\|HOME" ~/.config/systemd/user/hermes-<name>.service
```

## Key Rules

- Each profile is ISOLATED — its own config, env, skills, and memory
- Skills must be EXPLICITLY synced to each profile's `skills/` directory
- Profile SOUL.md is the AGENT'S KNOWLEDGE of what skills exist — keep it updated
- Gateway restart required after any skill or SOUL.md change
- Use `kill <pid>` then `hermes -p <profile> gateway run` to restart gracefully
- **Credentials for terminal tools:** `.env` alone is unreliable — inject into systemd `Environment=` directives

### Fallback Model Provider Compatibility

When a profile's primary model uses a custom router (e.g. `custom:router9`), the `fallback_model.provider` must point to a provider that supports the same API routes. If fallback uses a different provider (e.g. `custom:commandcode`), it may attempt an unsupported API mode (e.g. `/responses`) and crash the gateway with HTTP 404. The crash-restart cycle then causes stale group-join state, producing symptoms indistinguishable from Telegram privacy-mode bugs.

**Check fallback health:**
```bash
grep -r 'fallback_model' ~/.hermes/profiles/*/config.yaml
```

**Fix pattern:**
```yaml
fallback_model:
  provider: custom:router9                    # same router as primary
  model: cmc/deepseek/deepseek-v4-flash       # cheap/free model for fallback
```

**Verify after fix:**
```bash
hermes -p <profile> gateway run      # foreground first, watch for NotFoundError
# Once stable, Ctrl+C and restart in bg
```
