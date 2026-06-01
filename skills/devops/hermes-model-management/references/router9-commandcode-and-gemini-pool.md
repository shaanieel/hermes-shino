# Router9 Commandcode + Gemini Vision Pool Notes

Session-derived implementation notes for Hermes setups that use a local OpenAI-compatible router (9router) plus Google Gemini vision.

## 1) Command Code endpoint shape

Command Code Provider API expects the `/provider/v1` prefix:

- `POST https://api.commandcode.ai/provider/v1/chat/completions`
- `POST https://api.commandcode.ai/provider/v1/messages`
- `GET  https://api.commandcode.ai/provider/v1/models`

Do not configure base URL as plain `/v1` for this provider.

## 2) Router9 primary + Commandcode as fallback

User preference in this session:

- Keep primary unchanged on router9 (`custom:router9`, `cx/gpt-5.5`)
- Put Command Code in `fallback_model`, not as primary default

This avoids surprise default-provider switches.

## 3) Quick command pitfall and fix

A broken pattern was observed:

- keys with leading slash (`/cmd-pro`)
- shell command string values (`hermes config set ...`)

Working messaging-safe pattern:

```yaml
quick_commands:
  cmd-pro:
    type: alias
    target: /model custom:router9:cmc/deepseek/deepseek-v4-pro --global
```

Use `/restart` after config edits so gateway command registry reloads.

## 4) "Vision fallback" for multiple Google accounts

For Gemini, use credential pooling (same provider) rather than cross-provider fallback:

```bash
hermes auth list gemini
```

In this session, a 3-key gemini pool was present. Recommend:

```yaml
credential_pool_strategies:
  gemini: fill_first
```

This keeps account #1 as primary and auto-rotates to account #2/#3 on limit/error.
