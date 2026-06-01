# VPS monitor script: pitfalls & debugging notes

Pitfalls encountered during development of `scripts/vps-monitor.sh` on Ubuntu VPS.

## ps sorting: `--sort=-rss` vs `--sort=-%rss`

- `ps aux --sort=-rss` — works on most Ubuntu/Debian, but NOT on busybox ps or stripped-down containers.
- `ps aux --sort=-%rss` — may also fail on some ps builds.
- **Reliable fallback:** `ps -eo rss,pcpu,comm --sort=-rss` — the BSD-style `-eo` format is universally supported.

## RAM parsing: `free -b` field counting

- `free -b | awk '/^Mem:/{print $2,$3,$4,$5,$6,$7}'` — field order is `total, used, free, shared, buff/cache, available`.
- Do NOT do arithmetic directly on `awk` output with `read -r` then bash math — `3.6Gi` strings poison integer arithmetic.
- **Pattern:** `to_int() { echo "$1" | tr -d -c '0-9'; }` then `RAM_TOTAL=$(to_int "$(free -b | awk '/^Mem:/{print $2}')")`.
- Use `awk` for the extraction and bash for integer math — never mix them in one expression.

## Port deduplication: IPv4 + IPv6

- `ss -tlnp` lists BOTH IPv4 (`0.0.0.0:PORT`) and IPv6 (`[::]:PORT`) entries for dual-stack listeners.
- Without dedup, every port appears twice in the report.
- `ss` sometimes uses `*` instead of `0.0.0.0` for wildcard — treat `*` same as public.
- **Solution:** awk associative array `seen[port]` + `public[port]` flag; prefer public entry over localhost.

## SSH session age: `who -u` field format

On Ubuntu `who -u`:
```
$1=user  $2=tty  $3=date(Y-M-D)  $4=time(HH:MM)  $5=idle  $6=PID  $7=(IP)
```

- Do NOT try `date -d "$3"` alone — it fails because `$3` is just the date part.
- Use `date -d "${date} ${time}" +%s` to combine date+time before parsing.

## jq dependency

- The delta/comparison feature (`LAST_FILE`) requires `jq` to read previous state.
- Script gracefully degrades: if `jq` is missing or `LAST_FILE` doesn't exist, shows "Cek pertama" message.
- `jq` is installed by default on Ubuntu 20.04+ but may be absent on minimal images.

## Cronjob: script path format

- Cronjob `script` parameter MUST be just the filename (e.g. `vps-monitor.sh`), NOT an absolute path.
- Scripts live in `~/.hermes/scripts/` — the scheduler resolves relative paths there.
- Error when using absolute path: `"Script path must be relative to ~/.hermes/scripts/"`.

## Hermes process cleanup: identification & kill

When Hermes has 3+ processes running, some are stale. NEVER guess which to kill — identify by cmdline:

```bash
# 1. List all Hermes processes with full command
for pid in $(pgrep -f hermes); do
    args=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
    ppid=$(awk '/PPid:/{print $2}' /proc/$pid/status 2>/dev/null)
    echo "PID=$pid | parent=$ppid | $args"
done
```

**Role identification by cmdline:**
- `gateway run --replace` → Gateway (DON'T KILL — disconnects Telegram)
- `hermes` without `gateway` → Active CLI session (DON'T KILL — kills current chat)
- `hermes_cli.main dashboard --host 0.0.0.0 --port 8080` → Orphan web dashboard (SAFE to kill)
- `hermes` with parent=1 and uptime > 1hr → Stale session (SAFE to kill)

**Common pitfall:** `kill PID` (SIGTERM) may not work on Hermes processes — they catch signals. Always use `kill -9 PID` for force kill. After killing, re-run `ps aux | grep hermes` to confirm (may still show stale entries from process cache — run again after 1-2 seconds). **Race condition:** if `kill -9 PID` returns "No such process", the earlier `kill PID` (SIGTERM) already terminated it. The error is benign — don't retry or investigate.

**Note:** Don't use the `.venv` in the cmdline to distinguish — Hermes installs have both `venv` and `.venv` directories. A process using `.venv` isn't necessarily a different role.

## RAM diagnosis: group by function, not by process

When user asks "why is RAM high", don't just dump `ps aux` sorted. Group by categories the user understands:

1. **WAHA/Docker:** Chromium + Node.js processes → "WAHA ~900 MB"
2. **Hermes Agent:** All python/hermes processes → "Hermes ~600 MB (N processes)"
3. **Web services:** next-server, cloudflared, workerd → "webstream ~200 MB"
4. **Database:** mariadbd/mysqld → "MariaDB ~90 MB (aaPanel dependency)"
5. **Panel:** BT-Panel, BT-Task → "aaPanel ~110 MB"

This grouping tells the user what they can safely act on (stop WAHA, kill stale Hermes) vs what they shouldn't touch (MariaDB = aaPanel breaks).

## Orchestration pattern

For VPS health monitoring cronjobs:
1. Create as `no_agent=true` so the script IS the job (no LLM overhead, no model routing failure surface).
2. Use `schedule="every 1h"` for recurring, or `every 30m` for tighter monitoring.
3. Delivery: `"origin"` sends to the chat that requested it.
4. Keep updates atomic: save current state to `/tmp/vps-monitor-last.json` after rendering so next run has a baseline.
