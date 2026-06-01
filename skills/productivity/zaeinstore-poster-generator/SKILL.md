---
name: zaeinstore-poster-generator
description: Generate Shopee product content (poster, judul, deskripsi, video TikTok) from ZAEINSTORE uploadshopee.zaeinstore.workers.dev. Use when user asks to generate product content, poster, or listing for Shopee via ZAEINSTORE.
---

# ZAEINSTORE Poster Generator

Generates complete Shopee product content: poster (JPEG), product title, description, and TikTok promo video from the ZAEINSTORE web app.

## Trigger
- User asks to generate content/poster/listing for Shopee
- User mentions "ZAEINSTORE", "zaein", or "uploadshopee"
- User mentions specific movie/TMDB ID to generate

## Speed is critical
User wants FAST execution. No analysis, no explanation, no overthinking. Click the buttons, get the files, send them. Minimal text.

## Workflow

### 1. Navigate & Setup
Use `browser_navigate` to `https://uploadshopee.zaeinstore.workers.dev/`
- Click **Variasi 2**
- Click **# TMDB ID** tab
- Type the TMDB ID (e.g., 920 for Cars 2006)
- Click **Cari**
- Click the result card (shows movie name + ID)

### 2. Generate Poster → DOWNLOAD JPEG ⚠️
- Click **BUAT GAMBAR SEKARANG** (if disabled, force-enable via JS: `b.disabled=false; b.click()`)
- Wait 12-15 seconds for canvas render
- **Click ⬇ DOWNLOAD JPEG button** — this triggers a browser download, NOT canvas save
  - ❌ DO NOT extract canvas via `toDataURL()` — user wants the actual JPEG file
  - ✅ Click the DOWNLOAD JPEG button and wait for file to save

### 3. Product Title (Judul)
- Scroll to section ⑤
- Click **Film Animasi** button (or appropriate style)
- Wait for text to generate
- Click **📋 Copy** — title is now in clipboard

### 4. Product Description (Deskripsi) ⚠️
- Scroll to GENERATOR DESKRIPSI section
- Select options: Subtitle Indonesia, Bahasa English, GB, size 1
- Click **📋 Copy** button in the **GENERATOR DESKRIPSI** section (above, NOT the WhatsApp one)
  - ❌ Do NOT use the WhatsApp/Saluran WhatsApp description
  - ✅ Use the standard deskripsi Copy button (the first one)

### 5. TikTok Video
- Scroll to section ⑥ CARI & DOWNLOAD VIDEO TIKTOK
- Search field auto-fills from TMDB selection
- Click **🔄 Refresh** to load videos
- Pick ONE video (preferably short, <2 minutes, related to the film)
- Click the video thumbnail/duration text
- Click the **RED Download button** — video saves as MP4

### 6. Deliver Results
- Send all files to user via MEDIA: paths
- Include judul text and deskripsi text
- Clean up temp files

## Pitfalls
- **React state**: Buttons may show as `disabled` in DOM despite being visually active. Use JS to force-enable:
  ```js
  b.disabled = false; b.removeAttribute('disabled'); b.click();
  ```
- **Canvas vs JPEG**: DOWNLOAD JPEG button triggers actual file download. `canvas.toDataURL()` is wrong — user explicitly rejected this approach.
- **Two Copy buttons**: GENERATOR DESKRIPSI has two Copy buttons. The top one copies the Shopee description. The bottom one copies WhatsApp format. Use the top one.
- **TikTok dynamic render**: Video thumbnails are loaded via RapidAPI. After clicking Refresh, wait 5-6 seconds for results. Clicking the duration text selects the video and reveals the Download button.
- **TMDB ID vs Name search**: TMDB ID (e.g., 920) is more reliable than name search (text "Cars" sometimes fails to show results).
- **Do NOT overcomplicate**: User says "ribet amat" — just click buttons. Don't extract text manually from DOM or body text. Click the Copy/Download buttons.
