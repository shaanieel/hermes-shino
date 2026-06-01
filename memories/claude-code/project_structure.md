---
name: project-structure
description: Ringkasan folder proyek di a:\!BUATWEBKEREN\CODEX\DRIVE WEB + BOT TELGRAM
metadata: 
  node_type: memory
  type: project
  originSessionId: bf9c4a5d-d75f-4cba-ae8e-70236cf7bb24
---

Direktori kerja: `a:\!BUATWEBKEREN\CODEX\DRIVE WEB + BOT TELGRAM\`

Sub-folder:
- `Zaeinstore/` — index.html + worker.js (BUKAN git repo) — toko/storefront frontend + Cloudflare worker
- `admin zaeinstore/` — index.html (BUKAN git repo) — admin panel storefront
- `adminweb1/` — git repo `shaanieel/adminweb1`, branch aktif `codex/update-2026-05-18`; admin panel (Cloudflare Worker + public assets) untuk webstream
- `bottelegram/` — git repo `shaanieel/bottelegram`, branch `codex/update-2026-05-18`; Python bot Telegram dengan modules untuk player4me, gdrive, subtitles
- `drive/` — git repo `shaanieel/drive`, branch `codex/update-2026-05-18`; Cloudflare Worker untuk Drive + index.html UI
- `webstream/` — git repo `shaanieel/webstream`, branch `codex/remove-streamex-references-2026-05-19`; web streaming film (worker, public, supabase, gdi-worker)

**Why:** User mengelola beberapa repo di satu workspace; struktur ini perlu diingat agar tahu mana yang versi-controlled dan mana yang tidak.

**How to apply:** Kalau user minta cek status atau commit, jalankan git command di sub-folder yang sesuai. Jangan coba git pada Zaeinstore/admin-zaeinstore.

Lihat juga [[github-repos]].
