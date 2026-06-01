# Telegram Bot Setup Notes - May 2026

Session pattern: user wanted Hermes connected to Telegram and expected the assistant to perform setup, not just give instructions. The user became frustrated when prerequisites were not stated clearly up front.

## User-facing lesson

Start with a short checklist of exactly what is needed:

- Bot token from `@BotFather`
- Bot username
- User/chat ID
- Whether access should be DM-only or group-enabled
- Desired capabilities: images, PDFs, browser, web, files, terminal, memory

Then proceed with configuration.

## Successful Configuration Pattern

- Store `TELEGRAM_BOT_TOKEN` in `~/.hermes/.env`.
- Set `TELEGRAM_HOME_CHANNEL` to the user's chat ID.
- Quote `TELEGRAM_HOME_CHANNEL_NAME` if it contains spaces.
- In `~/.hermes/config.yaml`, set Telegram allow lists:

```yaml
telegram:
  allowed_chats: '<chat_id>'
  allow_from: '<user_id>'
  free_response_chats: '<chat_id>'
  require_mention: false
  reply_to_mode: all
```

- Verify tools with `hermes tools list --platform telegram`; for the successful setup, web, browser, terminal, file, code_execution, vision, image_gen, tts, skills, todo, memory, session_search, clarify, delegation, cronjob, messaging, and computer_use were enabled.
- Verify the token with Telegram `getMe` using the token from the environment.
- Start/verify gateway with `hermes gateway status` and `hermes logs gateway --since 2m`.
- Install durable gateway service using `hermes gateway install --force` and re-check status.
- Send a test Telegram message when possible.

## Pitfall Seen

An unquoted `TELEGRAM_HOME_CHANNEL_NAME=BOSS SHOLEH` caused shell sourcing to interpret `SHOLEH` as a command. Fix by quoting values with spaces:

```dotenv
TELEGRAM_HOME_CHANNEL_NAME="BOSS SHOLEH"
```

## Final Handoff Shape

Keep the final answer compact:

- Bot connected and gateway running
- Access is restricted to the provided ID
- Capabilities enabled
- Test commands/messages to send, e.g. `halo shino`, `baca gambar ini`, `ringkas PDF ini`, `buka browser dan cari ...`
- Warn not to share the bot token
