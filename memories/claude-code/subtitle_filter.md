---
name: subtitle-filter
description: Bot otomatis filter subtitle — drop forced/narrative dan duplikat per bahasa, pilih size terbesar
metadata:
  type: project
---

Bot punya fitur auto-filter subtitle di pipeline Player4Me. Kalau satu video punya beberapa subtitle dengan bahasa sama, bot pilih satu aja.

**Lokasi kode:** `bottelegram/modules/player4me_auto_subs.py:387-407` (`_subtitle_rank` + `_select_best_subtitles_per_language`)

**Aturan ranking** (per bahasa):
1. Non-forced > forced (forced detected dari metadata `disposition.forced` atau pola nama: "Forced", "Forced Narrative", "ForcedNarrative")
2. Kalau status forced sama, **size lebih besar menang**

**Contoh:**
- `Indonesian.srt` (50KB) + `Indonesian Forced Narrative.srt` (5KB) → pilih Indonesian normal
- `English.srt` (40KB) + `English.ass` (60KB) → pilih yang 60KB

**Detection forced** ada di `subtitle_extractor.py:136-153` — pakai `is_forced_subtitle_hint()`.

**Why:** Forced/narrative subtitle biasanya cuma sub partial (cuma untuk dialog asing/sign), bukan full sub. Dulu user manual filter, sekarang auto.

**How to apply:** Fitur ini auto-jalan di flow `/upload_player4me` dan command terkait. Bot bakal log message `"Filter subtitle: N dipilih, M di-drop (prioritas non-forced, lalu ukuran terbesar)"`.
