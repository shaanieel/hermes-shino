---
name: api-provider-hidepulsa
description: User pakai Hidepulsa sebagai Anthropic API third-party provider untuk Claude Code dan agent project lain
metadata:
  type: reference
---

User pakai **Hidepulsa** (ai.hidepulsa.com) sebagai third-party Anthropic API provider — proxy/reseller yang ngasih akses ke model Claude dengan harga lebih murah dari Anthropic resmi.

**Detail koneksi:**
- Base URL: `https://ai.hidepulsa.com/v1`
- Auth: standard `x-api-key` header (sama kayak Anthropic resmi)
- Model name format: `kr/claude-opus-4.7`, `kr/claude-haiku-4.5`, kemungkinan ada `kr/claude-sonnet-4.6` juga (cek dashboard)

**Yang penting:**
- Provider ini **support tool use FULL** — Claude Code yang user pakai sekarang juga jalan via Hidepulsa (model ID di runtime: `kr/claude-opus-4.7`)
- Cocok untuk: chatbot biasa + agent dengan tool use (Claude Agent SDK)
- API compatible dengan Anthropic SDK official — tinggal set `base_url` saat init `Anthropic()` / `AsyncAnthropic()`

**Cara pakai di kode Python:**
```python
import anthropic
client = anthropic.AsyncAnthropic(
    api_key=os.getenv("ANTHROPIC_API_KEY"),
    base_url="https://ai.hidepulsa.com/v1",
)
resp = await client.messages.create(
    model="kr/claude-opus-4.7",  # atau kr/claude-haiku-4.5
    ...
)
```

**Why save:** Tiap kali project butuh Claude API, defaultnya pakai Hidepulsa, BUKAN Anthropic resmi. User udah punya kuota di sana, lebih murah.

**How to apply:** Saat user nyebut "API Anthropic" / "third-party API" / "Claude API key kamu", langsung asumsikan Hidepulsa. JANGAN nanya provider-nya lagi — kalau perlu konfirmasi base URL/model spesifik, cek dashboard https://ai.hidepulsa.com.

**Caveat:** Subscription expired tiap periode (terakhir liat: 26/05/2026). Kalau API tiba-tiba balik 401 di future-chat, kemungkinan kuota habis atau subscription belum di-renew.
