# 9router Credential Data Location & Extraction

When a user wants to extract credentials from a 9router install (e.g., for porting to a laptop or creating a backup repo), the data lives in two places:

## Data Locations

| Path | Contents | Keep? |
|------|----------|-------|
| `/opt/9router-data/db.json` | All provider connections (API keys/tokens), combos, settings, API keys, password hash | ✅ CORE |
| `/opt/9router-data/auth/cli-secret` | CLI auth secret (64-char hex) | ✅ CORE |
| `/opt/9router-data/jwt-secret` | JWT signing secret (64-char hex) | ✅ CORE |
| `/opt/9router-data/machine-id` | Machine identifier (64-char hex) | ✅ CORE |
| `/opt/9router-data/db/data.sqlite` | Request logs, history (~500MB+) | ❌ HEAVY |
| `/opt/9router-data/request-details.json` | Verbose request details (~2MB) | ❌ HEAVY |
| `/opt/9router-data/bin/cloudflared.exe` | Cloudflare tunnel binary (65MB) | ❌ HEAVY |
| `/opt/9router-data/runtime/` | Node.js runtime deps | ❌ SKIP |
| `/opt/9router-data/logs/` | Server logs | ❌ SKIP |
| `/opt/9router-data/tunnel/` | Tunnel config | ❌ SKIP |
| `/opt/9router-data/update/` | Updater state | ❌ SKIP |
| `/opt/9router-data/mitm/` | MITM certs + aliases | Optional |

Also:
- `~/.hermes/.env` — may contain `OPENAI_API_KEY` used by the router
- `~/.hermes/config.yaml` — `custom_providers` section referencing the router

## Extraction Procedure

```bash
mkdir 9router-credentials
cp /opt/9router-data/db.json 9router-credentials/
cp /opt/9router-data/auth/cli-secret 9router-credentials/
cp /opt/9router-data/jwt-secret 9router-credentials/
cp /opt/9router-data/machine-id 9router-credentials/
```

## What's Inside db.json

The `db.json` is a flat JSON file (~12KB) containing:

- **`providerConnections[]`** — API keys/tokens for each provider (Blackbox, NVIDIA, OpenRouter, Gemini, Kiro, Gemini CLI, etc.). Each entry has `apiKey`, `accessToken`, `refreshToken`, `expiresAt`, `providerSpecificData`.
- **`combos[]`** — Named model groups with their model lists (e.g., "zaein" combo maps to `cx/`, `bb/`, `nvidia/`, `gemini/` prefixed models)
- **`apiKeys[]`** — Custom API keys for accessing the router itself (`sk-...` keys)
- **`settings`** — Router config (password hash, strategies, ports, tunnel settings)

## Portable Repo Structure

```
9router/
├── db.json           # All provider credentials & combos
├── cli-secret        # Auth secret
├── jwt-secret        # JWT secret
├── machine-id        # Machine ID
└── README.md         # Setup instructions
```

## Pitfalls

- **db.json is PLAINTEXT credentials** — NEVER commit to a public repo. If pushing to GitHub, the repo must be PRIVATE.
- **data.sqlite is 500MB+** — don't include it. It's just request logs and history. The credentials in db.json are sufficient.
- **Tokens in db.json may be expired** — OAuth tokens (Kiro, Gemini CLI) have `expiresAt` fields. API keys (NVIDIA, OpenRouter, Gemini) don't expire unless revoked.
- **Password hash in settings** — the bcrypt hash (`$2b$...`) in `settings.password` is needed if `requireLogin: true`. Without it, the router login page won't work on the new machine.
- **Machine ID matters** — some API keys in db.json are tied to the machine ID (checked in `apiKeys[].machineId`). If copying to a different machine, those keys may not work without updating the machine-id file.
