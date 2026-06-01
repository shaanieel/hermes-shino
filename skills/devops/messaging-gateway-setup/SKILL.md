---
name: messaging-gateway-setup
description: Configure Hermes messaging gateway platforms such as Telegram, including tokens, whitelists, service startup, media/tool access, and user handoff.
---

# Messaging Gateway Setup

Use this when the user asks to connect Hermes/Shino/agent access to a messaging platform, especially Telegram, or asks for platform access to images, PDFs, browser, web, files, or other tools.

## Operating Rules

1. **Answer immediately with prerequisites.** If a credential or user action is needed, say exactly what is needed before doing long inspection. Users get frustrated if setup appears to stall without a checklist.
2. **Do not expose secrets.** Never repeat bot tokens in final replies or logs summaries. If the user pastes a token, store it in the credential store/environment and refer to it only as `TELEGRAM_BOT_TOKEN`.
3. **Prefer durable gateway service.** After verifying a manual gateway run, install/start the Hermes gateway service when appropriate so it survives logout.
4. **Whitelist early.** If the user provides a Telegram user/chat ID, configure `allowed_chats`, `allow_from`, and `free_response_chats` to limit access before announcing the bot as ready. For group access, append the negative group ID to `allowed_chats` and add it to `group_allowed_chats` while preserving the existing DM chat/user IDs so private chat still works.
5. **Verify from both sides.** Check platform API identity (`getMe` for Telegram), gateway logs/status, and send a short test message when possible.
6. **Execution-first preference handling.** If the user says "kamu aja yang ngerjain" / asks the agent to do the auth or restart directly, perform the concrete actions first (service restart, status verify, auth command), then report concise results. Avoid bouncing the user back to manual checklists unless a hard external step is unavoidable (e.g., inviting a kicked bot back to a Telegram group).

## Telegram Checklist

Ask the user for:

- Bot username, e.g. `@my_agent_bot`
- Bot token from `@BotFather`
- User/chat ID for access control
- Whether the bot should respond only in DM or also in groups/topics
- Required tool abilities: image/PDF reading, browser, web, terminal, file operations, memory, cron, etc.

## Hermes Configuration Pattern

Set credential values in `~/.hermes/.env`:

```dotenv
TELEGRAM_BOT_TOKEN=<token>
TELEGRAM_HOME_CHANNEL=<chat_id>
TELEGRAM_HOME_CHANNEL_NAME="<human label>"
```

Set Telegram policy in `~/.hermes/config.yaml`:

```yaml
telegram:
  reactions: false
  channel_prompts: {}
  allowed_chats: '<chat_id>'
  allow_from: '<user_id>'
  free_response_chats: '<chat_id>'
  require_mention: false
  reply_to_mode: all
```

If enabling group access, use the group-specific allow lists instead of opening unrestricted access.

## Tool Access

Check the enabled toolsets for the Telegram platform before telling the user a capability is ready. For media-heavy Telegram bots, ensure the platform has access to at least:

- `vision` for images/screenshots
- `file` and document extraction tools for PDFs and uploaded files
- `browser` and `web` for browsing/search tasks
- `terminal`/`code_execution` only if the user expects local execution and accepts the risk
- `memory` if the bot should remember names/preferences

## Vision/Image Setup

If uploaded images produce `No LLM provider configured for task=vision provider=auto`, treat it as a routing/configuration gap, not a broken image tool. Keep the user's main chat provider unchanged and add a vision-capable task model/provider, then restart the gateway.

Typical fixes:

```yaml
task_models:
  vision:
    provider: openrouter
    model: google/gemini-2.5-flash
```

For an OpenAI-compatible custom router (for example 9router) that can route multimodal models, use the configured custom provider name instead:

```yaml
task_models:
  vision:
    provider: custom:9router
    model: google/gemini-2.5-flash
```

For direct Google/Gemini access, Hermes' bundled Gemini provider accepts `GOOGLE_API_KEY` or `GEMINI_API_KEY` and has provider aliases `gemini`, `google`, `google-gemini`, and `google-ai-studio`. Many installs route auxiliary image reading through `auxiliary.vision`, not `task_models.vision`:

```yaml
auxiliary:
  vision:
    provider: gemini
    model: gemini-2.5-flash
    base_url: ''
    api_key: ''
    timeout: 120
    extra_body: {}
    download_timeout: 30
```

After editing config and `.env`, run `hermes gateway restart` and test with a fresh image upload. If protected-file tooling refuses to edit `~/.hermes/.env` or `~/.hermes/config.yaml`, give the user exact minimal commands to run rather than looping on blocked writes.

## Bot Health Check (Quick Triage)

When a user reports bots are "mati" (dead), always run the full diagnostic, not just `systemctl status`. A process in `ps aux` is NOT proof of functionality — it can be stuck in a fatal error loop (Forbidden, credential 404, fallback crash) with no recent log activity.

**Quick triage command:**
```bash
ps aux | grep 'hermes.*gateway' | grep -v grep
for pid in $(pgrep -f 'hermes.*gateway'); do
  echo "=== PID $pid ==="
  journalctl _PID=$pid --no-pager -n 10 2>&1
done
```

Then for each PID, check the last log entries. If the most recent logs are error traces (Forbidden, NotFoundError, BadRequest) with no newer activity, the process is alive but the bot is dead. Full triage table and per-profile commands: `references/telegram-bot-health-diagnostics.md`.

## Verification

Run or equivalent:

```bash
hermes tools list --platform telegram
hermes gateway status
hermes logs gateway --since 2m
```

For Telegram API validation, use the token from the environment, not inline in the command:

```bash
set -a; . ~/.hermes/.env; set +a
python3 - <<'PY'
import json, os, urllib.request
url = 'https://api.telegram.org/bot' + os.environ['TELEGRAM_BOT_TOKEN'] + '/getMe'
print(json.load(urllib.request.urlopen(url, timeout=20)))
PY
```

Start durably when ready:

```bash
hermes gateway install --force
hermes gateway status
```

## Telegram Group Behavior

When a Telegram bot works in DMs but stays silent in groups, check delivery and Hermes gates separately:

1. **Telegram delivery first.** BotFather privacy mode is enabled by default. With privacy ON, Telegram only delivers slash commands, replies to the bot, service messages, and admin/channel cases. To receive ordinary group chatter, turn privacy off in BotFather or make the bot a group admin.
2. **Rejoin after privacy changes.** Telegram caches privacy state when the bot joins; remove and re-add the bot after changing BotFather `Group Privacy`.
3. **Hermes authorization.** `TELEGRAM_ALLOWED_USERS`/`allow_from` still controls which senders can trigger the bot. If using chat-scoped group authorization, put negative group IDs in `TELEGRAM_GROUP_ALLOWED_CHATS`/`telegram.group_allowed_chats`, not the sender allowlist.
4. **Mention gating.** If `telegram.require_mention: true`, groups trigger only on replies to the bot, `@botusername`, `/command@botusername`, or configured `telegram.mention_patterns`.
5. **Observed context mode.** To let the bot read group chatter as context without auto-replying, combine `allowed_chats`, `group_allowed_chats`, `require_mention: true`, and `observe_unmentioned_group_messages: true`.

Useful safe group config:

```yaml
telegram:
  allowed_chats:
    - "-1001234567890"
  group_allowed_chats:
    - "-1001234567890"
  require_mention: true
  observe_unmentioned_group_messages: true
  exclusive_bot_mentions: true
  mention_patterns:
    - "^\\\\s*shino\\\\b"
```

For multi-bot routing details, see `references/telegram-exclusive-bot-mentions.md`.

## Pitfalls

- Quote environment values containing spaces, e.g. `TELEGRAM_HOME_CHANNEL_NAME="BOSS SHOLEH"`.
- If `hermes gateway install` prompts, pipe or answer both startup and autostart questions intentionally.
- A bot can only message a user if the user has started the bot or Telegram already permits that chat; if sendMessage fails, ask the user to send `/start`.
- If a manually started gateway exists, installing with replace semantics may swap it for the service; re-check `hermes gateway status` after install.
- Do not assume a group is broken until testing `@botusername halo`, reply-to-bot, and `/help@botusername`; those distinguish Telegram delivery/privacy from Hermes filters.
- Keep final status concise: what was configured, what was verified, and the exact next test message to send.
- **Multi-bot "Chat not found".** When running multiple Hermes profiles as separate Telegram bots (e.g. designer + reviewer + default) targeting the same group, EVERY bot token must be individually invited. Bot A being in the group does NOT mean Bot B can send there. `telegram.error.BadRequest: Chat not found` = this specific bot hasn't joined that chat. Fix: invite via Telegram UI → group info → Add Member → search bot's @username. This is the #1 crash cause for multi-profile setups.

- **`require_mention: true` silently defeated by BotFather privacy.** This is the #1 cause for "I set `require_mention: true` but all bots still answer everything." Telegram's default Privacy Mode only delivers messages that mention the bot or are replies/commands. When privacy is ON, every message Hermes receives was already addressed to that bot — so Hermes can't distinguish mentions from non-mentions, and `require_mention: true` has no effect. The fix: (1) in BotFather, turn Group Privacy OFF for every bot that should only answer on mention; (2) kick and re-add each bot to the group so Telegram picks up the new privacy state; (3) restart that bot's Hermes gateway so it re-reads the join state. After these three steps, Hermes receives ALL group messages and `require_mention: true` can filter properly. Symptoms before fix: every bot answers every message even though config looks correct.

- **Fallback provider crash mimics privacy-mode bug.** When a profile gateway crashes on startup because the `fallback_model.provider` hits a 404 (e.g. `custom:commandcode` trying `/responses` which it doesn't support), the symptom is identical: every bot appears to answer everything, because they're cycling through crash-restart with stale state. Check `ps aux | grep gateway` for stable uptime before concluding privacy-mode didn't work. If the gateway keeps dying, grep logs for `NotFoundError` or `fallback` before re-applying the privacy fix.

- **ANY BotFather toggle change requires kick + re-add.** Telegram caches the bot's join state at invite time. Whether you toggle Group Privacy, `allow_bot_to_bot`, inline mode, or any other BotFather setting — the change does NOT propagate to groups the bot is already in. Symptom: setting looks correct in BotFather but the bot behaves as if nothing changed. Fix: (1) change the toggle in BotFather, (2) kick the bot from the group, (3) re-add it, (4) restart the bot's Hermes gateway. This is the #1 cause of "I changed the setting but it still doesn't work."

- **`require_mention: true` and `exclusive_bot_mentions` silently defeated by `free_response_chats`.** When a group chat ID appears in BOTH `free_response_chats` and `allowed_chats`, the `free_response_chats` entry overrides ALL mention gating — `require_mention: true`, `exclusive_bot_mentions`, and `mention_patterns` are all ignored. The bot responds to EVERY message in that group. `free_response_chats` is designed as an allowlist for chats that should NEVER require mention (e.g. DMs, admin groups). If the user wants a group to be mention-only, that group must NOT appear in `free_response_chats`. Only user DMs and trusted groups where the bot should always respond belong there. Fix: remove the group ID from `free_response_chats`, keep it in `allowed_chats` and `group_allowed_chats`. For multi-bot groups, ALSO verify BOTH profiles have `exclusive_bot_mentions: true` and per-bot `mention_patterns` (e.g. `['@ShinoDesignBot', '@ShinoDesign']`). A profile missing `exclusive_bot_mentions` will still answer every message even when `free_response_chats` is fixed.

- **`patch`/`write_file` blocked on `config.yaml` and `.env`.** Hermes protects credential/config files from direct file writes. Attempting `patch(path='~/.hermes/config.yaml', ...)` or `write_file(path='~/.hermes/.env', ...)` returns a denial. The correct workaround is the CLI: `hermes config set <section>.<key> <value>`. For per-profile configs, prepend `HERMES_HOME=/home/ubuntu/.hermes/profiles/<name>`.

- **`hermes config set` and negative IDs.** When a config value starts with `-` (like Telegram group IDs `-1004276656221`), the CLI interprets it as a flag and rejects the command. Fix: use `--` separator: `hermes config set -- telegram.group_allowed_chats "-1004276656221,-1003776215924"`. Without `--`, the error is `error: unrecognized arguments: -1004276656221`.

## Multi-Profile Independent Bots (3+ Bots, 3+ Profiles)

When the user wants 3 independent Telegram bots each running a different AI model, each profile must have its own systemd service with `HERMES_HOME` pointing to the profile directory. Without this, gateway status falsely reports "running" because all profiles share the default PID — they're not truly independent.

**Prerequisites per profile:**
- Own `TELEGRAM_BOT_TOKEN` in the profile's `.env`
- Own `config.yaml` with the profile's model, telegram section, and allowed chats
- Profile must already exist (`hermes profile create <name>`)

**Setup:** Create `~/.config/systemd/user/hermes-<profile>.service` per profile, each with `HERMES_HOME=/home/ubuntu/.hermes/profiles/<profile>`. Then `systemctl --user daemon-reload && systemctl --user start hermes-<profile> && systemctl --user enable hermes-<profile>`.

**Crucially:** Do NOT restart the running default gateway. Create the service files, daemon-reload, start the new services — the existing gateway stays untouched. The user explicitly said "gausah restart, perbaiki aja" — fix in place, don't disrupt running services.

**Verification:** `systemctl --user list-units --type=service | grep hermes` should show 3 separate services with different PIDs. If they share a PID, `HERMES_HOME` is pointing to the wrong directory.

**Drain-hang on service restart.** After a config change, `systemctl --user restart` may hang indefinitely because the gateway is draining active agent sessions (up to `agent.gateway_timeout`, default 1800s). The service shows `deactivating (stop-sigterm)` and won't honor further stop commands. Fix in order: (1) `systemctl --user reset-failed <service>` to clear the dead state, (2) `systemctl --user start <service>` to bring it back fresh. If `reset-failed` also hangs, the process may need a direct `kill <pid>` first. After restart, verify with `systemctl --user is-active <service>` which should return `active`.

Full template and commands: `references/multi-profile-systemd-services.md`.

## References

- `references/telegram-bot-health-diagnostics.md` covers rapid gateway triage: dead-bot signals, error-to-fix mappings, raw vs systemd gateway detection, and multi-profile diagnostics.
- `references/gemini-credential-pools-and-vision.md` captures direct Gemini vision routing plus the correct `hermes auth` credential-pool workflow for multiple Google API keys.
- `references/telegram-bot-setup-2026-05.md` captures a concrete setup transcript pattern and verification notes from a successful Telegram gateway setup.
- `references/telegram-group-silence-troubleshooting.md` summarizes the Hermes/Telegram group gates and config patterns for silent group bots.
- `references/telegram-multi-bot-mention-failure.md` captures the BotFather privacy mode / `require_mention` interaction bug and the three-step fix (privacy OFF → kick/re-add → gateway restart).
- `references/telegram-groups-and-gemini-vision-2026-05.md` captures direct Gemini `auxiliary.vision` routing and preserving DM access while adding a Telegram group ID.
- `references/commandcode-and-browser-harness-2026-05.md` captures Command Code as a Hermes custom provider plus Browser Harness install/connection notes.
- `references/telegram-slash-command-dispatch.md` covers the three-tier slash command resolution chain in `gateway/run.py`, how to debug "Unknown command", and how to add new commands.
- `references/telegram-exclusive-bot-mentions.md` covers `exclusive_bot_mentions` multi-bot routing, per-profile `mention_patterns`, and Telegram bot-to-bot limitation with workarounds.
- `references/multi-profile-systemd-services.md` covers multi-profile systemd service template, multi-bot PITFALLS, verification commands, and the "fix in place, don't restart" workflow rule for independent Telegram bots.