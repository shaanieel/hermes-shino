---
name: hermes-model-management
description: Manage Hermes model providers, fallbacks, and quick-switching via slash commands.
---

# Hermes Model & Provider Management

Manage custom model providers, fallback chains, and fast model-switching in Hermes Agent.

## Triggers

Use this skill when the user wants to:
- Add a new custom provider (OpenAI/Anthropic-compatible API)
- Configure fallback models for redundancy
- Set up quick slash commands for switching between models
- Organize models via local routing proxies (e.g., 9router combos)
- Switch the active model or provider

## Core Concepts

### custom_providers vs model.provider

- `model.provider` — the active provider. Only one, set via `model.default` + `model.provider`.
- `custom_providers` — list of named provider configs (base_url, key_env, api_mode). These are *definitions* that can be referenced by `model.provider`, `fallback_model.provider`, etc.
- `fallback_model` — automatic failover when the primary provider is unreachable (rate limits, 503, connection errors).

### PITFALL — Don't silently change the default

When asked to add a provider, confirm where it should go:
- **Primary** (`model.provider` + `model.default`) — replaces the current active model.
- **Fallback** (`fallback_model`) — safety net, only used when primary fails.
- **Just defined** (`custom_providers` entry only) — available but not active.

**Always ask** before overwriting `model.default`. This was a hard correction from the user.

## Step 1: Add a custom provider

```yaml
custom_providers:
- name: commandcode
  base_url: https://api.commandcode.ai/provider/v1
  key_env: COMMAND_CODE_API_KEY
  api_mode: chat_completions
```

`api_mode` can be `chat_completions` (OpenAI format) or `messages` (Anthropic format). Most third-party APIs use `chat_completions`.

## Step 2: Set up fallback (recommended)

```yaml
fallback_model:
  provider: custom:commandcode
  model: gpt-5.5
```

This activates automatically on 429/503/529/connection failures. No user action needed.

## Step 2b: Auxiliary vision — understanding fallback limitations

**Critical context:** auxiliary services (vision, compression, web_extract, etc.) do NOT use `fallback_model`. They only use the single provider configured under their section. Full limitations doc: `references/auxiliary-services-limitations.md`.

When the user asks about vision/image analysis but their main model lacks native vision (e.g., DeepSeek), Hermes auto-delegates to `auxiliary.vision`. If that provider fails, image analysis breaks — no automatic cross-provider failover.

### Same-provider credential pooling (preferred for Gemini)

If you have multiple Google/Gemini accounts, set up credential pooling so Hermes rotates through healthy keys:

1. Add multiple Gemini credentials to the `gemini` pool:

```bash
hermes auth add gemini --type api-key --api-key "<google_key_2>"
hermes auth add gemini --type api-key --api-key "<google_key_3>"
hermes auth list gemini
```

2. Choose rotation behavior in `config.yaml`:

```yaml
credential_pool_strategies:
  gemini: fill_first    # stick to primary key, rotate on limit/error
  # gemini: round_robin # optional: spread traffic across keys
```

3. Keep auxiliary vision on Gemini:

```yaml
auxiliary:
  vision:
    provider: gemini
    model: gemini-2.5-flash
```

**Why this works:** if one Google key is rate-limited/temporarily unavailable, Hermes rotates to the next healthy Gemini credential automatically.

**Pitfall:** don't call this "fallback provider" unless you are switching to a different provider (OpenRouter/xAI/etc.). For multiple Google accounts, this is credential-pool failover.

## Step 3: Quick commands for fast model switching

Add to `quick_commands` in `config.yaml` so the user can switch models with a single slash command. **Do not** define quick-command keys with a leading `/`, and **do not** use bare string shell commands for messaging-platform switches. Use structured `type: alias` entries that point to Hermes' built-in `/model` command:

```yaml
quick_commands:
  cmd-flash:
    type: alias
    target: /model custom:router9:cmc/deepseek/deepseek-v4-flash --global
  cmd-pro:
    type: alias
    target: /model custom:router9:cmc/deepseek/deepseek-v4-pro --global
  cmd-codex:
    type: alias
    target: /model custom:router9:cx/gpt-5.5 --global
```

**Usage flow:** user types `/cmd-flash` or `/cmd-pro` in chat. If they want a clean context on the new model, then send `/new` after the switch.

**Pitfall:** `/new` starts a fresh conversation, so warn the user that active chat context is lost. If context matters, give them a short recap to paste or save durable setup details to memory before suggesting `/new`.

This is much faster than editing `config.yaml` or remembering full model IDs, and it works from messaging gateways once Hermes has reloaded the config.

## Step 4: Validate the configuration

```bash
python3 -c "import yaml; yaml.safe_load(open('$HOME/.hermes/config.yaml')); print('valid')"
```

## Local router pattern (e.g., 9router)

Some users run a local proxy (e.g., 9router on port 20128) that exposes model "combos" — named groups of models from multiple upstream providers. Benefits:
- Single endpoint (`http://127.0.0.1:20128/v1`)
- Combo names abstract model selection (e.g., `Commandcode`, `cx/gpt-5.5`)
- Can combine models from different APIs behind one provider

In this pattern, `custom_providers` defines the local router, and `model.default` uses its model IDs directly:

```yaml
custom_providers:
- name: router9
  base_url: http://127.0.0.1:20128/v1
  key_env: OPENAI_API_KEY
  api_mode: chat_completions

model:
  default: cx/gpt-5.5
  provider: custom:router9
```

List available models: `curl -sS http://127.0.0.1:20128/v1/models | python3 -m json.tool`

### PITFALL — 9router db.json is STALE; always query SQLite for combos

9router writes to two data stores: `db.json` (~12KB flat JSON) and `db/data.sqlite` (~500MB SQLite). They are NOT always in sync — combos created after the last db.json snapshot will appear in SQLite but NOT in db.json. `curl /v1/models` also queries the SQLite backend, so model lists are current.

**ALWAYS query the live SQLite for combo names**, not db.json:

```bash
python3 -c "
import sqlite3
conn = sqlite3.connect('/opt/9router-data/db/data.sqlite')
for row in conn.execute('SELECT name FROM combos ORDER BY createdAt DESC'):
    print(row[0])
"
```

**PITFALL:** `curl /v1/models` shows individual models but NOT combo names. Combos are only visible in SQLite's `combos` table or the 9router dashboard UI.

### PITFALL — Model name prefix confusion (cmc vs cmx vs cx)

Users may verbalize model prefixes loosely (e.g. "cmx" for commandcode). The actual prefixes on 9router:

| Prefix | Provider | Example |
|--------|----------|---------|
| `cmc/` | Command Code (via 9router) | `cmc/deepseek/deepseek-v4-pro` |
| `cx/` | Codex / OpenAI (via 9router) | `cx/gpt-5.5` |
| `bb/` | Blackbox AI | `bb/claude-sonnet-4.6` |
| `kr/` | Kiro AWS | `kr/deepseek-3.2` |
| `gc/` | Gemini CLI | `gc/gemini-3-flash-preview` |

Always cross-check the exact model name from `curl /v1/models` before writing to config — never trust a verbally-spoken model ID without verification.

### PITFALL — Model name exists upstream but not in router

Local router proxies (e.g. 9router) expose only a subset of upstream models. A model name that works directly at the upstream API **may not exist** in the router's model list. This is the single most common cause of "model not found" / "bad request" errors with local proxies.

**Example:** `cmc/google/gemini-3.5-flash` — `cmc/` prefix routes through commandcode upstream, but commandcode doesn't offer Gemini. The router's `/v1/models` will not include it. Valid Gemini models on 9router use different prefixes: `gemini/gemini-3-flash-preview`, `gc/gemini-3-flash-preview`, `bb/gemini-3-flash-preview`.

**Diagnosis:**
```bash
# List ALL models the router exposes, filter for the provider you want
curl -sS http://127.0.0.1:20128/v1/models | python3 -c "
import json,sys
data = json.load(sys.stdin)
for m in data['data']:
    if 'gemini' in m['id'].lower():
        print(f\"  {m['id']}\")
"
```

**Fix:** Use the exact model ID from the router's `/v1/models` response — not the name from the upstream provider's docs.

### PITFALL — Multi-profile model name drift

When running multiple Hermes profiles (`designer`, `reviewer`, etc.) through the same router, each profile's `config.yaml` has its own `model.default` setting. These can drift independently — one profile may reference a model that was removed from the router while another still uses a valid one.

**Symptoms:** one bot works, another silently fails with `BadRequestError` / `NotFoundError`.

**Fix:** cross-check all profile configs against the router's actual model list:
```bash
for profile in default designer reviewer; do
  cfg="$HOME/.hermes/profiles/$profile/config.yaml"
  [ "$profile" = "default" ] && cfg="$HOME/.hermes/config.yaml"
  model=$(grep -A1 "^model:" "$cfg" | grep "  default:" | head -1)
  echo "$profile → $model"
done
```

### PITFALL — Switching to a provider not routed by the proxy

When `model.provider` is set to a local router proxy (e.g., `custom:router9`), **all model changes still go through that proxy**, even if you run `/model` and pick Google Gemini or another provider in the interactive picker. The router can't proxy to providers it doesn't know about, and the request fails.

**Symptoms:** "error" / no response when switching to Gemini/Anthropic/etc. while router is the active provider. `hermes doctor` shows the API key is valid and the target provider has healthy credentials — the problem is the routing layer, not the credentials.

**Fix:** Switch `model.provider` directly to the target provider — don't go through the router:

```bash
# Instead of /model (which keeps the router as provider), set directly:
hermes config set model.provider gemini
hermes config set model.default gemini-2.5-flash
# Then /reset or restart gateway
```

To switch back: `hermes config set model.provider custom:router9` + `hermes config set model.default cx/gpt-5.5`.

**Quick command workaround:** add a dedicated quick command that changes BOTH provider and model:

```yaml
quick_commands:
  cmd-gemini:
    type: alias
    target: /model gemini:gemini-2.5-flash --global
```

The `/model` slash command accepts `provider:model` syntax and will switch both at once, bypassing the router.

## Multi-Profile Mixed-Provider Pattern

Each profile (`default`, `designer`, `reviewer`) has its own `config.yaml` and can use different providers and models independently. This is the correct pattern for running multiple bots with different AI backends.

**Verify profile configs do NOT collide:** every profile's `model.provider` + `model.default` combination must be valid for that provider. A profile using native Gemini must NOT have `custom:router9` as its provider — or requests will route through the proxy and fail.

### Reference: Boss Sholeh's 3-bot setup

| Profile | Model | Provider | Fallback |
|---------|-------|----------|----------|
| `default` (Shino) | `cmc/deepseek/deepseek-v4-pro` | `custom:router9` | `CODEX` (custom:router9) |
| `designer` (ShinoDesign) | `CODEX` | `custom:router9` | `cmc/deepseek/deepseek-v4-flash` (custom:router9) |
| `reviewer` (ShinoReview) | `gemini-2.5-flash` | `gemini` | `cmc/deepseek/deepseek-v4-flash` (custom:router9) |

Shino + Designer: both go through 9router — same provider, different combos. Reviewer: Gemini native — switches `model.provider` entirely, not just the model name.

### Switching a profile between router and native provider

```bash
# Set profile to Gemini native (bypasses router)
HERMES_HOME=~/.hermes/profiles/reviewer hermes --profile reviewer config set model.provider gemini
HERMES_HOME=~/.hermes/profiles/reviewer hermes --profile reviewer config set model.default gemini-2.5-flash

# Set profile to 9router
HERMES_HOME=~/.hermes/profiles/designer hermes --profile designer config set model.provider custom:router9
HERMES_HOME=~/.hermes/profiles/designer hermes --profile designer config set model.default CODEX
```

### Fallback provider mismatch is normal

A profile using native Gemini CAN still have a 9router-based fallback. The fallback only kicks in when the primary provider fails (rate limits, 503, connection errors) — it doesn't affect normal operation. But if the intent is zero-router for a profile, clear `fallback_model` entirely or set it to a same-provider model.

- `references/command-code-models.md` — Command Code Provider API models and endpoints
- `references/router9-commandcode-and-gemini-pool.md` — Session notes: router9 primary + Commandcode fallback, quick command alias format, Gemini credential-pool failover
- `references/9router-combos-reference.md` — Live combo inventory with model prefixes, test commands, and fallback config pattern
- `references/9router-credential-data.md` — 9router credential data locations (`/opt/9router-data/`), what to extract vs skip (539MB SQLite vs 12KB JSON), portable repo structure, and pitfall notes
- `references/auxiliary-services-limitations.md` — Auxiliary services (vision, compression, etc.) have no cross-provider fallback chain; workarounds and credential pool strategy
- `references/debugging-model-errors.md` — Diagnostic playbook: when user says "model X error/not working", step-by-step debugging from provider check through gateway logs
- `scripts/check-profile-models.sh` — Cross-check all profile config model names against router `/v1/models` for multi-profile setups
