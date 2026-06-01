# Telegram Slash Command Dispatch Architecture

## Three-Tier Resolution (gateway/run.py lines 7480–7758)

When a user sends `/command` in Telegram, the gateway resolves it in order:

### Tier 1 — Built-in Commands

Hardcoded in `gateway/run.py`. Each has its own `_handle_*` method:

| Command | Handler method |
|---------|---------------|
| `/model` | `_handle_model_command` |
| `/help` | `_handle_help_command` |
| `/tools` | `_handle_tools_command` |
| `/reset` | `_handle_reset_command` |
| `/new` | `_handle_new_command` |
| `/compact` | `_handle_compact_command` |
| `/stop` | `_handle_stop_command` |
| `/reasoning` | `_handle_reasoning_command` |
| `/sethome` | `_handle_set_home_command` |
| `/kanban` | `_handle_kanban_command` |
| `/retry` | `_handle_retry_command` |
| `/undo` | `_handle_undo_command` |
| `/profile` | `_handle_profile_command` |
| `/approve` | `_handle_approve_command` |
| `/deny` | `_handle_deny_command` |
| `/update` | `_handle_update_command` |
| `/debug` | `_handle_debug_command` |
| `/fast`, `/verbose`, `/footer`, `/yolo`, `/usage`, `/insights`, `/bundles`, `/compress`, `/reload-mcp`, `/reload-skills`, `/codex-runtime`, `/personality`, `/restart`, `/title` | (various) |

**Key detail:** The `canonical` name is always lowercased. Commands like `/Model` resolve to `/model`.

### Tier 2 — Plugin Commands

Dispatched via `hermes_cli.plugins.get_plugin_command_handler()`. Plugins register their own handlers. If no handler found → falls through to Tier 3.

### Tier 3 — Skill Commands

Every installed skill auto-registers as `/<skill-name>`. For example:
- Skill `claude-code` → `/claude-code`
- Skill `code-review` → `/code-review`

Telegram autocomplete converts hyphens to underscores (`/claude-code` becomes `/claude_code`), so the gateway normalizes underscores back to hyphens before resolving.

Skill commands are resolved in two sub-pass:
1. **Bundle commands** — `/bundle-name` loads multiple skills
2. **Individual skill commands** — `/skill-name` loads one skill

If the skill is **disabled per-platform**, a message is returned: `"The X skill is disabled for telegram. Enable it with: hermes skills config"`

### Fallback — Unknown Command

If no tier matches, the gateway replies:
```
Unknown command `/review`. Type /commands to see what's available,
or resend without the leading slash to send as a regular message.
```

This message is produced at line 7746–7758 of `gateway/run.py`. The check is:
```python
if command.replace("_", "-") not in GATEWAY_KNOWN_COMMANDS:
    return f"Unknown command `/{command}`. ..."
```

`GATEWAY_KNOWN_COMMANDS` is automatically derived from `COMMAND_REGISTRY` in `hermes_cli/commands.py`.

## Debugging "Command Not Found"

1. **Check if it's a known built-in:** `grep "canonical.*commandname" gateway/run.py`
2. **Check if it's a skill:** `ls ~/.hermes/skills/*/<name>/SKILL.md`
3. **Check if it's in COMMAND_REGISTRY:** `search_files --pattern "CommandDef\(\"<name>" --path hermes_cli/commands.py`
4. **Check if skill is disabled:** look for per-platform disable at line 7718–7724

## Adding a New Command

For a simple skill-based command (like `/review`):
1. Create a SKILL.md in `~/.hermes/skills/<category>/<name>/SKILL.md`
2. Restart the gateway: `hermes gateway restart`
3. The skill auto-registers as `/<name>`

For a built-in command:
1. Add `CommandDef` to `COMMAND_REGISTRY` in `hermes_cli/commands.py`
2. Add handler `_handle_<name>_command` in `gateway/run.py`
3. Add dispatch `if canonical == "<name>"` in the dispatch block
4. Rebuild and restart

## Bot-to-Bot Limitation

This is separate from the dispatch chain. Even if `/review` existed as a command, Telegram bots cannot read messages from other bots — see `references/telegram-exclusive-bot-mentions.md` for details. The three-tier dispatch only applies to messages the Telegram API actually delivers to Hermes.
