---
name: bot-setup
description: Cara start bot Telegram lokal di laptop — venv, start_bot.bat, port 8787, env vars penting
metadata:
  type: project
---

Bot Telegram (`bottelegram/`) jalan lokal di laptop. Setup-nya:

**Cara start:**
- `start_bot.bat` (recommended) — auto-sync requirements + auto-restart max 5x kalau crash
- atau manual: `cd bottelegram && venv\Scripts\activate && python bot.py`

**Yang harus ada di folder bottelegram/:**
- `venv/` — Python 3.11 virtualenv (bikin dengan `python -m venv venv` lalu `pip install -r requirements.txt`)
- `.env` — secrets (token Telegram, Bunny, Player4Me, Supabase, BOT_API_SECRET, dll)
- `secrets/credentials.json` + `secrets/token.pickle` — Google Drive OAuth
- `data/jobs.json` — history antrian (opsional, regenerate kalau gak ada)

**Bot HTTP API:**
- Listen di `http://127.0.0.1:8787` (hardcoded di `.env`: `BOT_API_HOST=127.0.0.1`, `BOT_API_PORT=8787`)
- Auth pakai header `Authorization: Bearer <BOT_API_SECRET>`
- Endpoint utama: `/api/health`, `/api/jobs?show=active`, `/api/jobs/movie`, `/api/jobs/series`

**Why:** Ini local-first bot — semua state (queue, history, OAuth token) ada di laptop. RDP cuma alternatif kalau laptop offline.

**How to apply:** Sebelum jalanin bot, pastikan `.env` + `secrets/` ada. Kalau pindah mesin, copy 3 hal: `.env`, folder `secrets/`, file `data/jobs.json` (kalau mau lanjut antrian) — sisanya regenerate dari git + `pip install`.

Lihat juga: [[drive-web-tunnel]] untuk cara expose bot ke drive web Cloudflare.
