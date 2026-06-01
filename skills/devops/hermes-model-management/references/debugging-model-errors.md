# Debugging "model error / not working" in Hermes

Quick diagnosis when a user says a model/provider isn't working. Run these in order — each step narrows the problem.

## Step 1: Check the active provider + model

```bash
grep -A2 "^model:" ~/.hermes/config.yaml
```

Key question: is `model.provider` a **local router proxy** (like `custom:router9`) or a direct provider (like `gemini`, `openrouter`, `anthropic`)?

If it's a router proxy, the proxy only routes to upstreams it knows about. Switching to a model the router can't proxy to = silent failure.

## Step 2: Check credential pool health

```bash
hermes auth list
```

Look for:
- Are credentials present for the target provider?
- Is the active arrow `←` pointing to a healthy credential?
- How many credentials in the pool? (More = better redundancy)

## Step 3: Test the API key directly

For Google/Gemini:
```python
import urllib.request, json
url = "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY"
data = json.loads(urllib.request.urlopen(url).read())
print(f"{len(data['models'])} models available")
```

For OpenAI-compatible endpoints:
```bash
curl -sS https://api.example.com/v1/models -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -20
```

If the API responds with models, the key is valid. If it fails:
- `401` — key is wrong/revoked
- `403` — key lacks permission
- Timeout/connection — network or endpoint URL wrong

## Step 4: Check custom_providers config

```bash
grep -A5 "custom_providers:" ~/.hermes/config.yaml
```

Verify `base_url` is correct and reachable. For local routers (127.0.0.1), make sure the router process is running:

```bash
curl -sS http://127.0.0.1:20128/v1/models | python3 -m json.tool | head -5
```

## Step 5: Run hermes doctor

```bash
hermes doctor
```

Shows provider status, tool availability, and credential gaps in one pass.

## Step 6: Check gateway logs

```bash
grep -i "error\|fail\|401\|403\|503\|timeout\|provider" ~/.hermes/logs/gateway.log | tail -30
```

Look for the exact error around the time the user reported the problem.

## Common patterns

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| "error" switching to Gemini | Router proxy can't route to Gemini | Set `model.provider` to `gemini` directly |
| 401 Unauthorized | Expired/revoked key | Get new API key, update in `.env` |
| 429 Rate limit | Key quota exhausted | Add credential to pool, set `fill_first` strategy |
| Timeout | Wrong `base_url` or router not running | Verify URL, restart router if needed |
| "Model not found" | Model name typo or not available at provider | List models via API, use exact name from response |
| BadRequest in one profile but not others | Model name drift across profiles | Cross-check all profile configs against router `/v1/models` |
| Telegram flood control in groups | Multiple bots/bot-profiles failing simultaneously | Fix root model error first; rate limit clears automatically |

## Multi-profile diagnostic shortcut

When multiple Hermes profiles (e.g., `designer`, `reviewer`) all fail at once with similar errors, skip individual profile debugging. The root cause is almost certainly the shared infrastructure layer:

1. **Check the router first:** `curl -sS http://127.0.0.1:20128/v1/models` — if the router is alive and returning models, auth is valid.
2. **Check each profile's model name** against the router model list — copy-paste the exact ID.
3. **Check the router logs:** `docker logs 9router --tail 50` — look for upstream credential failures (e.g., Kiro 403) that might degrade but not kill the router.
4. **Only then** dive into per-profile configs.

## Telegram flood control as a diagnostic signal

When multiple Hermes profiles fail simultaneously in the same Telegram group and all try to send error/status messages, Telegram applies a flood-control rate limit (RetryAfter N seconds). This is a **symptom** of the underlying model failure, not a separate problem. Fix the model issue and the flood control clears on its own. Do not spend time debugging flood control — it's the messenger, not the message.
