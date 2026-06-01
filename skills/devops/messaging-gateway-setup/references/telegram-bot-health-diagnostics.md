# Telegram Bot Health Diagnostics

Quick diagnostic commands for determining whether Hermes gateway bots are actually functional — not just alive in `ps aux`. A process showing in `ps aux` can be stuck in an error loop (Forbidden, credential 404, fallback crash) and functionally dead.

## Quick Triage (60 seconds)

```bash
# 1. Find ALL gateway processes — systemd services AND raw processes
ps aux | grep 'hermes.*gateway' | grep -v grep
systemctl --user list-units --type=service | grep hermes
systemctl list-units --type=service | grep hermes

# 2. Check recent logs per PID for fatal error loops
for pid in $(pgrep -f 'hermes.*gateway'); do
  echo "=== PID $pid ==="
  journalctl _PID=$pid --no-pager -n 10 2>&1
done

# 3. Quick API test per bot
curl -s "https://api.telegram.org/bot<TOKEN>/getMe"
```

## Dead-Bot Signals (process exists but bot is non-functional)

| Symptom in Logs | Root Cause | Fix |
|---|---|---|
| `telegram.error.Forbidden: Forbidden: bot was kicked from the supergroup chat` | Bot removed from group | Re-add bot to group, restart its gateway |
| `HTTP 404: No active credentials for provider: <name>` | 9router/credential expired or empty | Refresh credential pool, restart gateway |
| `NotFoundError` on fallback model | Profile's `fallback_model.provider` is 404 | Fix or remove fallback, restart gateway |
| No recent log entries but process exists | Process hung/blocked on I/O | Kill and restart |
| `Bot was blocked by the user` | User blocked bot in DM | Unblock or use different chat |

## Functional Verification

After fixing, NEVER just check `ps aux`. Send a test message:

- **DM test:** Send `halo` — should respond within 10s
- **Group test:** `@botusername halo` — especially if `require_mention: true`
- **Gateway API test:** `curl "http://localhost:8080/health"` (dashboard) + check logs for new entries

## Gateway Process Patterns

Raw processes (no systemd) show as:
```
python -m hermes_cli.main gateway run --replace
```

Implications:
- **No auto-restart on crash** — if the process dies, bot stays dead
- **Manual restart required:** `hermes gateway run --replace`
- **Multiple `--replace` duplicates possible** over time — check for stale PIDs

systemd-managed gateways show as:
```
hermes-gateway.service (loaded active running)
```
These auto-restart on crash (better for production).

## Multi-Profile Diagnostics

When running multiple profiles as independent bots:
```bash
# List all gateway PIDs with their HERMES_HOME
for pid in $(pgrep -f 'hermes.*gateway'); do
  echo "PID=$pid HOME=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep HERMES_HOME || echo 'default') CMD=$(cat /proc/$pid/cmdline | tr '\0' ' ')"
done

# Per-profile log check
HERMES_HOME=/home/ubuntu/.hermes/profiles/designer hermes logs gateway --since 5m
HERMES_HOME=/home/ubuntu/.hermes/profiles/reviewer hermes logs gateway --since 5m
```
