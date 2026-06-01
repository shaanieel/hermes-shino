# Gemini Vision and Credential Pools

Use this when Hermes Telegram/image reading uses direct Google Gemini and the user wants multiple API keys.

## Vision routing

Hermes installs may route uploaded image analysis through `auxiliary.vision` rather than `task_models.vision`:

```yaml
auxiliary:
  vision:
    provider: gemini
    model: gemini-2.5-flash
```

Set exactly one of these in `~/.hermes/.env`:

```dotenv
GOOGLE_API_KEY=<primary key>
# or GEMINI_API_KEY=<primary key>
```

`GEMINI_API_KEY` is an alias for `GOOGLE_API_KEY`.

## Credential pool

Do not hand-write a `credential_pool:` list in `config.yaml`. Hermes credential pools live in `~/.hermes/auth.json` and should be managed with `hermes auth`:

```bash
hermes auth add gemini --type api-key --api-key "<second_google_key>"
hermes auth list gemini
```

Expected list shape:

```text
gemini (2 credentials):
  #1  GOOGLE_API_KEY       api_key env:GOOGLE_API_KEY ←
  #2  Kedua                api_key manual
```

For even rotation across Google keys, set:

```yaml
credential_pool_strategies:
  gemini: round_robin
```

Then restart the gateway:

```bash
hermes gateway restart
```

## Safety

If the user pasted a real API key into chat, advise them to rotate/regenerate it in Google AI Studio and store the replacement only in `.env` or via `hermes auth add`.
