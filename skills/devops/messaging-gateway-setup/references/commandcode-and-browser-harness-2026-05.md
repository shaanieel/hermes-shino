# Command Code Provider and Browser Harness Notes

Use these notes when integrating external coding/browser tools into a Hermes profile for Telegram/CLI sessions.

## Command Code API as a Hermes custom provider

Command Code exposes an OpenAI-compatible provider endpoint at:

```text
https://api.commandcode.ai/provider/v1
```

The models endpoint is:

```text
https://api.commandcode.ai/provider/v1/models
```

Configure it as a Hermes custom provider while keeping existing providers intact:

```yaml
custom_providers:
- name: commandcode
  base_url: https://api.commandcode.ai/provider/v1
  key_env: COMMAND_CODE_API_KEY
  api_mode: chat_completions
```

Then store the official API key in the Hermes environment as `COMMAND_CODE_API_KEY` and restart the gateway. Do not paste or repeat the key in chat/log summaries.

To make it primary:

```yaml
model:
  default: gpt-5.5
  provider: custom:commandcode
```

To keep the current primary provider and only use Command Code as backup, add it as a fallback instead of changing `model.provider`.

Observed model IDs from the public models endpoint included `gpt-5.5`, `gpt-5.4`, `gpt-5.3-codex`, `gpt-5.4-mini`, `claude-sonnet-4-6`, `claude-opus-4-7`, `claude-haiku-4-5-20251001`, and `moonshotai/Kimi-K2.6`. Re-check `/models` before hard-coding because provider catalogs change.

## Browser Harness install pattern

`browser-use/browser-harness` is installed as an editable `uv` tool from a durable checkout, then its skill is symlinked into agent skill directories:

```bash
mkdir -p ~/Developer
git clone https://github.com/browser-use/browser-harness ~/Developer/browser-harness
cd ~/Developer/browser-harness
uv tool install -e .
mkdir -p ~/.codex/skills/browser-harness ~/.hermes/skills/browser-harness
ln -sf ~/Developer/browser-harness/SKILL.md ~/.codex/skills/browser-harness/SKILL.md
ln -sf ~/Developer/browser-harness/SKILL.md ~/.hermes/skills/browser-harness/SKILL.md
browser-harness --doctor
```

A successful install only provides the CLI and skill. It is not connected until a browser exposes CDP via one of:

- existing Chrome profile with `chrome://inspect/#remote-debugging` enabled and the user approving the attach popup;
- Chromium/Chrome launched with `--remote-debugging-port=9222 --user-data-dir=<non-default-dir>` and `BU_CDP_URL=http://127.0.0.1:9222`;
- Browser Use cloud with `BROWSER_USE_API_KEY`.

Do not conclude the harness is broken when `--doctor` reports no daemon/active connection; that usually means CDP is not enabled or no compatible browser is reachable yet.