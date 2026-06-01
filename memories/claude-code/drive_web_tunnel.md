---
name: drive-web-tunnel
description: Drive web (Cloudflare Worker drivee) reach bot lokal lewat Cloudflare Tunnel — setup URL via wrangler secret BOT_API_BASE
metadata:
  type: project
---

Drive web kamu = Cloudflare Worker bernama `drivee` (folder `drive/`, `wrangler.toml`). Worker ini gak bisa reach `127.0.0.1:8787` langsung (jalan di edge Cloudflare). Solusinya pakai **Cloudflare Tunnel**.

**Arsitektur:**
```
Drive Web UI (browser)
  → Cloudflare Worker "drivee" (edge)
    → BOT_API_BASE secret (URL tunnel)
      → Cloudflare Tunnel (cloudflared di laptop)
        → http://127.0.0.1:8787 (bot lokal)
```

**Cara setup tunnel (quick tunnel, sementara):**
1. Install: `winget install --id Cloudflare.cloudflared` (sekali aja)
2. Run di terminal terpisah, biarin jalan: `cloudflared tunnel --url http://127.0.0.1:8787`
3. Copy URL `https://xxxxx.trycloudflare.com` dari output
4. Update worker secret:
   ```bash
   cd "a:/!BUATWEBKEREN/CODEX/DRIVE WEB + BOT TELGRAM/drive"
   npx wrangler secret put BOT_API_BASE
   ```
   Paste URL — **HATI-HATI jangan ada spasi/newline trailing**, worker cuma trim slash bukan whitespace.

**Worker secrets yang ada** (cek dengan `npx wrangler secret list` di folder `drive/`):
- `BOT_API_BASE` — URL tunnel ke bot lokal
- `BOT_API_SECRET` — sama dengan `.env` bot (`kokkkronna21`)
- `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`
- `TMDB_API_KEY`
- `WEBSTREAM_API_BASE`, `WEBSTREAM_API_SECRET`

**Why:** Quick tunnel gratis, gampang, gak butuh domain. Tapi URL berubah tiap restart cloudflared → harus update secret tiap restart juga. Untuk solusi permanen pakai Named Tunnel (butuh domain di Cloudflare).

**How to apply:** Tiap kali kamu mulai sesi kerja: (1) start bot, (2) start cloudflared di terminal terpisah, (3) kalau URL tunnel beda dari sebelumnya, update `BOT_API_BASE` via `wrangler secret put`. Kalau drive web error "Fetch API cannot load" — pasti URL secret salah/spasi/expired.

**Common issue:** Kalau muncul "Fetch API cannot load: https://xxx.trycloudflare.com /api/jobs/series" (ada spasi sebelum `/api/`), itu artinya `BOT_API_BASE` ke-paste dengan trailing space. Re-set pakai `wrangler secret put` dan paste tanpa spasi.

Lihat juga: [[bot-setup]].
