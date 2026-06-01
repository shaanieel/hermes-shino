---
name: vps-remote-management
description: "Help users monitor and manage Ubuntu VPS instances through web panels, remote desktop, and lightweight observability tools."
version: 1.0.0
author: Hermes Agent
platforms: [linux]
metadata:
  hermes:
    tags: [vps, ubuntu, monitoring, remote-desktop, aapanel, cockpit, netdata]
    category: devops
---

# VPS remote management

Use this skill when a user wants to monitor, manage, or visually access an Ubuntu VPS from a browser or desktop client, especially when they ask for a "panel", "screen", "GUI", "layar", aaPanel, Cockpit, Netdata, RDP, VNC, or noVNC.

## Choose the right interface

1. Clarify whether the user wants a server management panel, monitoring dashboard, or a full desktop screen.
2. For hosting/site management, recommend aaPanel if it is already installed or fits the stack.
3. For lightweight system administration, recommend Cockpit.
4. For real-time performance graphs, recommend Netdata.
5. For an actual Ubuntu desktop screen, recommend XFCE plus XRDP for easiest client access, or noVNC if browser-only access is required.
6. Warn that full desktop environments are heavier than panels and can slow small VPS instances.

## Quick commands

Cockpit:

```bash
sudo apt update
sudo apt install cockpit -y
sudo systemctl enable --now cockpit.socket
sudo ufw allow 9090/tcp
```

Netdata:

```bash
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
sudo sh /tmp/netdata-kickstart.sh
sudo ufw allow 19999/tcp
```

XFCE + XRDP desktop:

```bash
sudo apt update
sudo apt install xfce4 xfce4-goodies xrdp -y
sudo systemctl enable --now xrdp
echo xfce4-session > ~/.xsession
sudo ufw allow 3389/tcp
```

aaPanel default access commonly uses port `7800`; if installed but unreachable, check both `ufw` and the VPS provider security group/firewall.

## Resource and safety checks

- Ask about VPS RAM before suggesting a desktop; 1 GB is usually too tight, 2 GB is workable, and 4 GB is more comfortable.
- Remind users to secure public panels: change default ports/passwords, enable SSL where supported, and avoid exposing databases such as MySQL port `3306` publicly.
- If the user reports slowness, check RAM, swap, CPU, disk, and heavyweight processes with `free -h`, `uptime`, `df -h`, and sorted `ps` output.
- For browser-heavy agent sessions on a VPS, stale headless Chromium processes can consume RAM; verify and clean them at host level when needed.

### Stale Hermes process cleanup

Hermes Agent can accumulate stale processes eating 100-200 MB each. Typical scenario on a busy VPS:

- **Gateway process:** `python -m hermes_cli.main gateway run --replace` — parent is usually init or tmux. NEVER kill this.
- **Active session:** `python3 .../venv/bin/hermes` or `python -m hermes_cli.main` — short uptime (< 1 hr). NEVER kill the one you're talking to.
- **Stale sessions/CLI:** Same binary but uptime hours/days, parent may be dead. SAFE to kill.
- **Orphan dashboard:** `hermes_cli.main dashboard --host 0.0.0.0 --port 8080` — SAFE to kill if not in use.

**Identification pattern:**
```bash
ps aux | grep "[h]ermes" | awk '{print $2, $6/1024"MB", $11, $12, $13}'
```
Check `/proc/$PID/cmdline` (null-separated, use `tr '\0' ' '`) and `/proc/$PID/status` (`PPid` field) to distinguish roles.

**Safe kill checklist:**
1. Run `ps aux | grep "[h]ermes"` — there should be 2 processes max (gateway + 1 session).
2. If 3+, identify the extras by cmdline + uptime.
3. First try `kill PID`. If the process persists, use `kill -9 PID`.
4. Re-run `ps aux | grep "[h]ermes"` — stale process cache may show dead PIDs for 1-2 seconds. If "No such process" appears on retry, the first kill already worked.
5. Re-verify with `free -h` — savings are instant.

**Race condition:** `kill -9` may fail with `"No such process"` — this means `kill` (SIGTERM) from step 3 already terminated it in the background. The error is benign; the PID is gone. Don't retry or investigate, just move on.

### WAHA RAM breakdown

WAHA runs Chromium + Node.js inside Docker. On `ps aux`, these appear as host processes with `--type=renderer` flags. To get WAHA-specific RAM:

```bash
WAHA_CR=$(ps aux | grep "[c]hromium" | awk '{s+=$6}END{printf "%.0f",s/1024}')
WAHA_NODE=$(ps aux | grep "[n]ode" | grep -iE "wa|waha" | awk '{s+=$6}END{printf "%.0f",s/1024}')
```

Typical WAHA footprint: 800-1200 MB total. Breakdown inside the container:
- **Chromium main** (~289 MB) — browser process
- **Chromium renderer** (~519 MB) — the WhatsApp Web tab (largest single consumer)
- **Chromium GPU/utility** (~160 MB) — GPU, network, storage, audio subprocesses
- **Node.js MainThread** (~264 MB) — WAHA API server
- **Xvfb** (~20 MB) — virtual display for headless browser

WAHA uses `--renderer-process-limit=2` and `--headless=new`. It communicates with Chromium via Chrome DevTools Protocol — without Chromium, WhatsApp cannot be accessed. Chromium processes CANNOT be killed independently; the entire container must be restarted.

**Critical:** do NOT suggest stopping WAHA unless the user volunteers it first. Many users depend on WAHA as WhatsApp infrastructure and consider it untouchable. The first hints that it's non-negotiable: "waha aku butuh banget" / "I really need WAHA". Group WAHA under "infrastructure" in reports, not under "optimization candidates."

If user asks to reduce RAM without touching WAHA, redirect to: stale Hermes processes, unused web services, 9router, or secondary bots (shaa-kimi-bot).

### aaPanel context

- **MariaDB** (`mariadb.service`): auto-installed by aaPanel as its internal database. ~80-90 MB RAM is normal, cannot be stopped without breaking aaPanel. Listens on `localhost:3306` — verify it's NOT public.
- **BT-Panel** (`bt.service`): the aaPanel web interface itself, ~100 MB RAM.
- aaPanel admin port: `888` (sometimes `8888` or `7800` depending on install).

## Automated health checks with Hermes cron

Use this flow when users ask for periodic VPS checks such as "now, then 3 minutes, then every 2 hours".

1. Send an immediate status first (run checks now), then set automation. During incidents, users expect current state before scheduler setup.
2. Prefer script-only cron jobs (`no_agent=true`) for infra checks to avoid model/API route failures.
3. Store executable scripts under `~/.hermes/scripts/` and reference them by relative name in cron (`script: "vps_health_check.sh"`).
4. For recurring schedules, use explicit recurring syntax such as `every 2h`; avoid ambiguous one-shot forms.
5. Keep one-shot follow-up separate from recurring monitor: one job for `3m` once, one job for `every 2h` forever.
6. Before `run`, `update`, or `remove`, call `cronjob(action='list')` and use the returned `job_id` to avoid "job not found" mistakes.

Reference scripts:
- `scripts/vps_health_check.sh` — basic health check (uptime, RAM, disk, load).
- `scripts/vps-monitor.sh` — full-featured: top processes, Docker, services, ports with ⚠️ warnings, SSH session ages, WAHA/9router breakdowns, RAM delta vs previous run, and auto-recommendations. Preferred for recurring cronjobs.
- `references/vps-monitor-pitfalls.md` — pitfalls encountered during dev: ps sorting portability, RAM parsing from `free -b`, IPv4/IPv6 port dedup, `who -u` field format on Ubuntu, jq dependency, cronjob script path format.

## Communication style

Keep advice practical and option-based. In Indonesian conversations, distinguish clearly between `panel web` and `desktop layar` because users may describe both as wanting to manage the VPS "pakai layar". When the user asks urgently for current VPS state, respond with direct health output first and keep explanation minimal.