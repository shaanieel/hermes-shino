# Gateway Failure Diagnosis Reference

## Default Profile Gateway Died (Tool Loop → SIGKILL)

### Symptoms
- `hermes gateway list` shows `✗ default (current) — not running`
- `systemctl --user status hermes-gateway` shows `failed (Result: signal)` with `code=killed, signal=KILL`
- Bot stops responding in Telegram/Discord
- Other profiles' gateways (designer, reviewer) are unaffected

### Root Cause
The same tool (typically `terminal`) failed ≥4 times in a single turn. The loop detector fired the tool-loop warning, and systemd's `TimeoutStopSec` eventually sent SIGKILL. After SIGKILL, systemd's `Restart=always` may or may not trigger depending on the RestartForceExitStatus and RestartSec config — but in practice it often stays dead.

### Recovery
```bash
systemctl --user restart hermes-gateway
sleep 3
hermes gateway list     # verify ✗ became ✓
```

### Prevention
- If a tool is timing out repeatedly in the same turn, systemd will eventually kill the process. The fix is to reduce tool timeout or fix the underlying cause (e.g., a hanging `terminal` call due to a stuck process).
- Gateway restart is fast (~2-3s) and non-destructive — other profiles' gateways continue running.

## Bot Kicked From Supergroup

### Symptoms
- Journal shows: `telegram.error.Forbidden: Forbidden: bot was kicked from the supergroup chat`
- Bot stops responding in group but may still work in DM

### Recovery
1. Manually re-add the bot to the group via Telegram
2. If the bot was kicked by Telegram's anti-spam, wait 1-2 minutes before re-adding
3. No gateway restart needed — bot re-connects on next message

## Designer Bot: No Active Credentials

### Symptoms
- Journal shows: `HTTP 404: No active credentials for provider: openai`
- Designer bot errors on every request

### Recovery
1. Check 9router credential status: `curl http://127.0.0.1:20128/credentials`
2. Re-add/refresh expired OpenAI key in 9router
3. No gateway restart needed — next request picks up fresh creds
