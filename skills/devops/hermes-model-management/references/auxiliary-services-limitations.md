# Auxiliary Services — Fallback Limitations & Workarounds

## What Hermes supports

| Feature | Automatic fallback chain? | Workaround available? |
|---------|--------------------------|----------------------|
| Main model (`model.provider`) | YES — `fallback_model` kicks in on 429/503/529/connection errors | Credential pools for same-provider rotate |
| Auxiliary vision | NO — single provider, no fallback chain | Credential pool (same provider) OR manual switch |
| Auxiliary compression | NO — same limitation | Manual switch |
| Auxiliary web_extract | NO — same limitation | Manual switch |
| Auxiliary (all others) | NO — same limitation | Manual switch |

## Why this matters

Auxiliary services (`auxiliary.vision`, `auxiliary.compression`, `auxiliary.web_extract`, etc.) do **not** consult `fallback_model`. They only use the single provider configured under their section. If that provider goes down, hits a rate limit, or runs out of quota, the auxiliary task fails silently or returns an error.

## Workaround 1: Same-provider credential pool (recommended when possible)

If you have multiple API keys for the same provider (e.g., multiple Google accounts for Gemini), use credential pools:

```bash
hermes auth add gemini --type api-key --api-key "<key_2>"
hermes auth add gemini --type api-key --api-key "<key_3>"
```

Configure rotation strategy in `config.yaml`:

```yaml
credential_pool_strategies:
  gemini: fill_first    # stick to primary, rotate on error
```

Keep auxiliary vision unchanged — Hermes auto-rotates through healthy credentials.

## Workaround 2: Manual provider switch (cross-provider)

Switch auxiliary vision to a different provider entirely:

```bash
# Switch to OpenRouter (accesses Claude/GPT vision models)
hermes config set auxiliary.vision.provider openrouter
hermes config set auxiliary.vision.model anthropic/claude-sonnet-4

# Or OpenAI
hermes config set auxiliary.vision.provider openai
hermes config set auxiliary.vision.model gpt-4o
```

This requires `/reset` or a new session to take effect.

## Workaround 3: OpenRouter as strategic hub

OpenRouter is a good choice for auxiliary services because it auto-routes to multiple models. If one model is down, OpenRouter's own routing may pick another.

### PITFALL: Don't assume cross-provider fallback exists

Users often assume that because the main model has fallback, auxiliary services do too. They don't. Always clarify this when discussing vision/image analysis capabilities with non-vision models (e.g., DeepSeek).

## Non-vision models + auxiliary vision

When the main model lacks native vision (DeepSeek, some open-weight models), Hermes auto-delegates image analysis to `auxiliary.vision`. This is transparent to the user — it happens inside `vision_analyze`. But if `auxiliary.vision.provider` fails, image analysis breaks entirely. The user sees an error, not a graceful degradation.
