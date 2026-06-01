---
name: codex-sessions
description: Lokasi & format riwayat percakapan Codex CLI di mesin user
metadata: 
  node_type: memory
  type: reference
  originSessionId: bf9c4a5d-d75f-4cba-ae8e-70236cf7bb24
---

Path: `C:\Users\shole\.codex\sessions\YYYY\MM\DD\rollout-<timestamp>-<uuid>.jsonl`

Format: JSONL, satu event per baris. Cari pesan user dengan pola:
`"role":"user","content":[{"type":"input_text","text":"..."}]`

Sesi terbaru ada di `2026/05/19/`. Sesi paling besar (17 MB) berisi banyak pekerjaan terkait fix klik-kanan player, hapus referensi "streamex", dan keamanan webstream.

**How to apply:** Kalau user nanya "lanjutin kerjaan dari chat sebelumnya" atau "cek session sebelumnya", baca file rollout terbaru di folder ini untuk konteks. Jangan baca seluruh file (bisa 17 MB+) — pakai grep untuk cari pesan user atau topik tertentu.
