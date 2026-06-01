---
name: zaeinstore-automation
description: Automate the ZAEINSTORE Poster Generator web app for Shopee product creation — TMDB search, poster gen, title gen, description gen, and TikTok video download.
---

# ZAEINSTORE Automation

Automate https://uploadshopee.zaeinstore.workers.dev/ — a web app for generating Shopee product listings from TMDB movie data.

## When to Use

- User asks to generate Shopee listing assets for a movie/series
- User says "generate poster for Cars 2006", "buat produk Shopee untuk film X"
- User wants poster + title + description + TikTok video in one shot

## Prerequisites

- CloakBrowser installed on VPS: `pip install cloakbrowser` (use `/usr/bin/python3` on Hermes VPS, not the Hermes venv)
- See `references/vps-cloakbrowser.md` for VPS-specific CloakBrowser setup

## Workflow (4 steps)

### Step 1: Setup — Variasi 2 + TMDB ID Search

Always use **TMDB ID mode** — it's more reliable than name search on this app.

```python
from cloakbrowser import launch
p = launch(headless=True).new_page()
p.goto("https://uploadshopee.zaeinstore.workers.dev/", timeout=20000, wait_until="domcontentloaded")

# Variasi 2 (template with editable name + poster)
p.evaluate('document.querySelectorAll("button").forEach(b=>{if(b.innerText.includes("Variasi 2")&&b.innerText.length<30)b.click()})')

# Switch to TMDB ID tab
p.evaluate('document.querySelectorAll("button").forEach(b=>{if(b.innerText.trim()=="# TMDB ID")b.click()})')

# Enter ID (e.g., 920 = Cars 2006)
p.evaluate('''document.querySelectorAll("input,textarea").forEach(el=>{
    if(el.placeholder&&el.placeholder.includes("TMDB ID")){
        el.value="920";
        el.dispatchEvent(new Event("input",{bubbles:true}));
        el.dispatchEvent(new Event("change",{bubbles:true}));
    }
})''')

# Click Cari
p.evaluate('document.querySelectorAll("button").forEach(b=>{if(b.innerText.trim()=="Cari"&&b.offsetParent)b.click()})')
time.sleep(3)

# Click the result card
p.evaluate("""document.querySelectorAll('*').forEach(el=>{
    if(el.innerText&&el.innerText.includes('Cars')&&el.innerText.includes('ID 920')&&el.offsetHeight>20){el.click()}
})""")
```

### Step 2: Generate Poster

The "BUAT GAMBAR SEKARANG" button is often **visually active but DOM-disabled**. Force-enable it:

```python
# Force enable + click
p.evaluate("""document.querySelectorAll('button').forEach(b=>{
    if(b.innerText.includes('BUAT GAMBAR SEKARANG')){
        b.disabled = false;
        b.removeAttribute('disabled');
        b.click();
    }
})""")
time.sleep(12)  # Wait for canvas render

# Extract poster from canvas as JPEG
cd = p.evaluate('document.getElementById("previewCanvas")?.toDataURL("image/jpeg",0.95)')
if cd:
    with open("poster.jpg","wb") as f:
        f.write(base64.b64decode(cd.split(",")[1]))
```

### Step 3: Title + Description

```python
# Scroll to section 5
p.evaluate("window.scrollTo(0,2400)"); time.sleep(1)

# Click "Film Animasi" for animation movies
p.evaluate('document.querySelectorAll("button").forEach(b=>{if(b.innerText.includes("Animasi"))b.click()})')
time.sleep(3)

# Description: Indonesia subtitle, English audio, GB size = 1, then Copy
p.evaluate("window.scrollTo(0,2700)"); time.sleep(1)

# Subtitle = Indonesia
p.evaluate("""document.querySelectorAll('button').forEach(b=>{
    let pa=b.parentElement?.parentElement?.innerText||'';
    if(b.innerText.trim()==='Indonesia'&&pa.includes('SUBTITLE'))b.click();
})""")

# Audio = English
p.evaluate("""document.querySelectorAll('button').forEach(b=>{
    let pa=b.parentElement?.parentElement?.innerText||'';
    if(b.innerText.trim()==='English'&&pa.includes('BAHASA'))b.click();
})""")

# Size selector = GB
p.evaluate('document.querySelectorAll("button").forEach(b=>{if(b.innerText.trim()=="GB"&&b.offsetParent)b.click()})')

# Fill size = 1
p.evaluate("""document.querySelectorAll('input').forEach(inp=>{
    if((inp.parentElement?.parentElement?.innerText||'').includes('SIZE')){
        inp.value='1';
        inp.dispatchEvent(new Event('input',{bubbles:true}));
    }
})""")

# Click Copy (copies to clipboard)
p.evaluate('document.querySelectorAll("button").forEach(b=>{if(b.innerText.trim()=="Copy")b.click()})')
```

### Step 4: TikTok Video (LIMITED)

**Known limitation**: The TikTok section renders video data in `innerText` but the actual video elements and Download button are controlled by JavaScript event handlers that require real UI interaction. Direct JS clicks on duration text (e.g., "0:30") don't reliably trigger the download flow.

**Current best-effort approach:**

```python
# Scroll + Refresh
p.evaluate("window.scrollTo(0, 5200)"); time.sleep(3)
p.evaluate('document.querySelectorAll("button").forEach(b=>{if((b.innerText||"").includes("Refresh"))b.click()})')
time.sleep(6)

# Read video durations from innerText (they ARE visible as text)
body = p.evaluate("document.body.innerText")
# Parse durations with regex: /^(\d+):(\d{2})$/

# Attempt click on a duration text
# This works to SELECT a video but the Download button may not appear
```

The `tiktok-api.semuapro.store` worker returns empty when called directly via curl. The RapidAPI keys embedded in the page are needed for auth.

**Fallback**: Tell the user which video durations are available and let them download manually, or use a different TikTok download service.

## Pitfalls

1. **Button `[disabled]` in DOM but visually active**: The React app sets `disabled` attribute on the generate button even when the state is valid. Always force-enable via JS.
2. **Name search unreliable**: Use TMDB ID mode. Common IDs: Cars=920, Avengers=299536, Interstellar=157336.
3. **`networkidle` timeout on VPS**: Use `wait_until="domcontentloaded"` on VPS. `networkidle` can hang indefinitely due to WebSocket connections.
4. **TikTok section invisible in viewport**: Content is below ~5000px. Scroll explicitly. Videos appear in `innerText` but interactive elements may not exist in DOM.
5. **Canvas element ID**: The poster canvas has `id="previewCanvas"`.

## Common TMDB IDs

| Film | ID |
|------|-----|
| Cars | 920 |
| Cars 2 | 49013 |
| Cars 3 | 260514 |
| Avengers: Endgame | 299534 |
| Interstellar | 157336 |
| Inception | 27205 |
