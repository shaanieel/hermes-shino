# 9router Combos Reference (as of 2026-05-29)

Combos live in SQLite at `/opt/9router-data/db/data.sqlite` table `combos`. The `db.json` flat-file is often stale — always query SQLite directly.

## Current Combos

| Combo | Models | Use |
|-------|--------|-----|
| **Commandcode** | 9 models: cmc/deepseek/deepseek-v4-pro, cmc/deepseek/deepseek-v4-flash, cmc/moonshotai/Kimi-K2.6, cmc/Qwen/Qwen3.6-Max-Preview, cmc/MiniMaxAI/MiniMax-M2.7, cmc/Qwen/Qwen3.6-Plus, cmc/moonshotai/Kimi-K2.5, cmc/zai-org/GLM-5, cmc/zai-org/GLM-5.1 | Default provider — primary AI |
| **CODEX** | 9 models: cx/gpt-5-codex, cx/gpt-5.1-codex-max-review, cx/gpt-5.5, cx/gpt-5.3-codex-high, cx/gpt-5.3-codex-high-review, cx/gpt-5.3-codex-none, cx/gpt-5.3-codex-xhigh-review, cx/gpt-5.3-codex-low-review, cx/gpt-5.3-codex-spark-review | Fallback — coding & review |
| **zaein** | 17 models: cx/gpt-5.1-codex-max, cx/gpt-5.3-codex, cx/gpt-5.3-codex-spark, cx/gpt-5.4-image, bb/claude-sonnet-4.6, bb/gpt-4o, bb/qwen3-coder-plus, bb/claude-sonnet-4.5, bb/claude-opus-4.6, bb/claude-opus-4-6, nvidia/kimi-k2.5, nvidia/glm4.7, nvidia/nv-embedqa-e5-v5, gemini/gemini-3-pro-image-preview, gemini/gemini-3.1-pro-preview, gemini/gemini-3.1-flash-lite-preview, gemini/gemini-3.1-flash-image-preview | Mega combo — all providers |
| **coding** | 6 models: cx/gpt-5.1-codex-max, cx/gpt-5.4, cx/gpt-5.3-codex-high, cx/gpt-5.3-codex, cx/gpt-5.4-image, cx/gpt-5.3-codex-spark | Codex-only coding |
| **bb** | 5 models: bb/claude-opus-4.6, bb/claude-sonnet-4.6, bb/claude-sonnet-4.5, bb/claude-opus-4-6, bb/claude-sonnet-4-6 | Blackbox Claude-only |
| **Hermes** | 3 models: openai-t1-sg/gpt-5.3-codex, gc/gemini-3-flash-preview, cx/gpt-5.5 | Light Hermes fallback |
| **kiroo** | 1 model: kr/claude-opus-4.7 | Kiro single-model |

## Model Prefixes

| Prefix | Provider | Description |
|--------|----------|-------------|
| `cmc/` | Command Code | DeepSeek, Kimi, Qwen, MiniMax, GLM, Step |
| `cx/` | Codex / OpenAI | GPT-5.x series |
| `bb/` | Blackbox AI | Claude, GPT-4o, Qwen Coder |
| `kr/` | Kiro AWS | Claude Opus, DeepSeek |
| `gc/` | Gemini CLI | Google Gemini models |
| `gemini/` | Google AI | Gemini Pro, Flash, Image |
| `nvidia/` | NVIDIA NIM | Kimi, GLM, Embed |
| `openai-t1-sg/` | OpenAI T1 SG | GPT models via Singapore region |

## Testing a Combo

```bash
API_KEY=$(python3 -c "import json,sqlite3; conn=sqlite3.connect('/opt/9router-data/db/data.sqlite'); print(conn.execute('SELECT data FROM apiKeys LIMIT 1').fetchone()[0])" | python3 -c "import json,sys; print(json.load(sys.stdin)['key'])")
# Alternative: from db.json  API_KEY=$(python3 -c "import json; d=json.load(open('/opt/9router-data/db.json')); print(d['apiKeys'][0]['key'])")

curl -sS http://localhost:20128/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"CODEX","messages":[{"role":"user","content":"OK"}],"max_tokens":5}'
```

## Fallback Pattern (Hermes config.yaml)

```yaml
model:
  default: cmc/deepseek/deepseek-v4-pro   # model langsung, bukan nama combo
  provider: custom:router9

fallback_model:
  provider: custom:router9
  model: CODEX                             # nama combo sebagai fallback
```
