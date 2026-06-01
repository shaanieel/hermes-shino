# GitHub Auth in Hermes Profile Gateways

When a Hermes profile bot (e.g., designer, reviewer) running as a systemd service with `HERMES_HOME` set reports "not logged into GitHub," the issue is that terminal subprocesses spawned by the gateway do not inherit `.env` profile variables reliably.

## Why It Happens

1. `gh auth status` works in the main/default profile (direct CLI session)
2. Profile `.env` has `GITHUB_TOKEN` set (but commented-out is a common miss)
3. `config.yaml` has `env_passthrough: [GITHUB_TOKEN, GH_TOKEN, HOME]`
4. Yet terminal tool inside the bot session still fails

Root cause: Hermes gateway may override `HOME` to `HERMES_HOME` (pointing to the profile directory), causing `gh` to search `~/.config/gh/hosts.yml` in the wrong location. Even with `HOME` in `env_passthrough`, the gateway's own process env may not pass through to child subprocesses.

## Fix Checklist (3 Layers)

### Layer 1: Profile .env
```
# ~/.hermes/profiles/<name>/.env
GITHUB_TOKEN=gho_...
GH_TOKEN=gho_...
```
→ Necessary but not sufficient on its own.

### Layer 2: config.yaml env_passthrough
```yaml
# ~/.hermes/profiles/<name>/config.yaml
terminal:
  env_passthrough: [GITHUB_TOKEN, GH_TOKEN, HOME]
```
→ Defense-in-depth, but may not reach terminal subprocess.

### Layer 3: Systemd Service Environment (THE FIX)
```ini
# ~/.config/systemd/user/hermes-<name>.service
Environment="HERMES_HOME=/home/ubuntu/.hermes/profiles/<name>"
Environment="GITHUB_TOKEN=gho_..."
Environment="GH_TOKEN=gho_..."
Environment="HOME=/home/ubuntu"
```

```bash
systemctl --user daemon-reload
systemctl --user restart hermes-<name>.service
```

## Verify

```bash
# Check env in the running process
PID=$(systemctl --user show hermes-<name>.service -p MainPID --value)
cat /proc/$PID/environ | tr '\0' '\n' | grep -E "GITHUB|GH_TOKEN|HOME"

# Simulate from process
env $(cat /proc/$PID/environ | tr '\0' '\n' | grep -v "^PATH\|^VIRTUAL_ENV\|^HERMES_HOME" | tr '\n' ' ') \
  PATH="/usr/bin:/home/ubuntu/.local/bin" HOME=/home/ubuntu \
  gh auth status
```

Expected: `✓ Logged in to github.com account <user> (GH_TOKEN)`
