# Multi-Profile Systemd Services for Independent Telegram Bots

When running 3+ Hermes profiles as separate Telegram bots, each profile needs its own systemd service with `HERMES_HOME` pointing to the profile directory (NOT the default `~/.hermes`). Without this,:
- All profiles share one PID — gateway status shows them as "running" but they're not independent
- Restarting one kills all
- Gateway crash-loops because profiles interfere with each other

## Service Template

For a profile named `<profile>`, create `/home/ubuntu/.config/systemd/user/hermes-<profile>.service`:

```ini
[Unit]
Description=Hermes Agent Gateway - <Human Name> Profile (<Model>)
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/home/ubuntu/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace
WorkingDirectory=/home/ubuntu/.hermes/hermes-agent
Environment="PATH=/home/ubuntu/.hermes/hermes-agent/venv/bin:/home/ubuntu/.hermes/hermes-agent/node_modules/.bin:/usr/bin:/home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="VIRTUAL_ENV=/home/ubuntu/.hermes/hermes-agent/venv"
Environment="HERMES_HOME=/home/ubuntu/.hermes/profiles/<profile>"
Restart=always
RestartSec=10
RestartMaxDelaySec=300
RestartSteps=5
RestartForceExitStatus=75
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=210
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
```

## Key differences from default service

| Setting | Default | Multi-profile |
|---------|---------|---------------|
| `HERMES_HOME` | `/home/ubuntu/.hermes` | `/home/ubuntu/.hermes/profiles/<name>` |
| `RestartSec` | `5` | `10` (more spacing to avoid thundering herd) |

### Gateway Drain Hang on Restart

When stopping/restarting a profile's gateway, it enters a `deactivating (stop-sigterm)` drain phase that can hang for several minutes while waiting for active agent sessions to finish. Do NOT wait for drain — use `systemctl --user stop <service>` followed by `reset-failed` and `start`:

```bash
# If gateway hangs in "deactivating":
systemctl --user stop hermes-<profile>   # may timeout, that's OK
systemctl --user reset-failed hermes-<profile>
systemctl --user start hermes-<profile>
```

### Negative Chat IDs in `hermes config set`

When using `hermes config set` with values that start with a dash (e.g. Telegram group IDs like `-1004276656221`), the dash is interpreted as a CLI flag. Use `--` before the value:

```bash
# WRONG — dash is parsed as a flag:
hermes config set telegram.group_allowed_chats "-1004276656221,-1003776215924"

# RIGHT — use -- to terminate flag parsing:
hermes config set -- telegram.group_allowed_chats "-1004276656221,-1003776215924"
```

For single values without commas (e.g. just one group), `hermes config set` may still work without `--` — only use it when you hit the `unrecognized arguments` error.

### Config is Protected — Use `hermes config set`, Not `patch`

`~/.hermes/config.yaml` and `~/.hermes/.env` are Hermes credential stores and cannot be edited directly via `patch` or `write_file`. Always use `hermes config set <key> <value>` for config changes. For profile-specific configs, prefix with `HERMES_HOME=/home/ubuntu/.hermes/profiles/<name>`.
# Verify all three are running independently:
systemctl --user list-units --type=service | grep hermes
```

Expected output — 3 separate PIDs:
```
hermes-designer.service  loaded active running
hermes-gateway.service   loaded active running
hermes-reviewer.service  loaded active running
```

## Verification

```bash
# Each should show its own PID, not shared:
hermes gateway status --profile <profile>
```

If profiles share a PID, the service isn't pointing to the right `HERMES_HOME`.

## Pitfalls

- **Profile must already exist** with its own `.env` (`TELEGRAM_BOT_TOKEN`) and `config.yaml` (model, telegram section, allowed chats). The service doesn't create profiles.
- **Each bot needs its own Telegram token** from @BotFather. Three profiles sharing one token = undefined behavior.
- **If a bot targets a group**, every bot token must be individually invited. Bot A in the group does NOT mean Bot B can send there. `telegram.error.BadRequest: Chat not found` = this specific bot hasn't joined.
- **Don't restart the running default gateway** when adding new profile services. Create the files, daemon-reload, start — the default gateway stays untouched.
