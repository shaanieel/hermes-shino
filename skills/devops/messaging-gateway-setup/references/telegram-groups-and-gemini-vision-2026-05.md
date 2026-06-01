# Telegram groups and Gemini vision notes (2026-05)

Session-derived details for Hermes Telegram gateway setup on a VPS using a custom OpenAI-compatible main provider plus direct Google/Gemini for vision.

## Vision routing

Observed failure:

```text
No LLM provider configured for task=vision provider=auto
```

Useful checks:

- `~/.hermes/config.yaml` may already contain `auxiliary.vision` with `provider: auto` and blank model fields.
- Hermes' bundled Gemini provider is `gemini` with aliases `google`, `google-gemini`, and `google-ai-studio`.
- It accepts API key env vars `GOOGLE_API_KEY` or `GEMINI_API_KEY`.
- Direct Gemini vision config can use:

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

Keep the main chat provider unchanged when only image reading is broken. Restart gateway after editing.

## Telegram group allowlist pattern

If the config already allows a DM chat/user, preserve it while adding the group. Example starting point:

```yaml
telegram:
  allowed_chats: '8966896495'
  allow_from: '8966896495'
  free_response_chats: '8966896495'
  require_mention: false
```

For group `-1004276656221` while keeping the DM working:

```yaml
telegram:
  allowed_chats: '8966896495,-1004276656221'
  allow_from: '8966896495'
  group_allowed_chats: '-1004276656221'
  free_response_chats: '8966896495,-1004276656221'
  require_mention: false
```

Use `require_mention: true` plus `mention_patterns` if the group should not free-respond to every visible message.

## Verification sequence

1. Restart: `hermes gateway restart`.
2. Test DM still works.
3. Test group with a plain message if `require_mention: false`.
4. Also test `@botusername halo` and `/help@botusername` to isolate Telegram delivery/privacy from Hermes filters.
5. If logs do not move on group messages, check BotFather Group Privacy, admin status, and remove/re-add the bot after privacy changes.
