---
name: cloakbrowser
description: Stealth Chromium browser via CloakBrowser — passes bot detection tests that standard CDP browsers fail. Use when the user needs to browse sites with anti-bot protection (Cloudflare, reCAPTCHA, FingerprintJS, etc.).
---

# CloakBrowser

Stealth Chromium binary with 58 C++ source-level fingerprint patches. Passes Cloudflare Turnstile, reCAPTCHA v3 (score 0.9), FingerprintJS, BrowserScan.

**Location:** Installed via pip in system Python (`/usr/bin/python3`)
**Binary:** `~/.cache/ms-playwright/chromium-1223/chrome-linux64/chrome` (Chromium 146, 377MB)

## Quick Usage

### Session-only (no cookies persist)

```bash
/usr/bin/python3 <<'PY'
from cloakbrowser import launch

browser = launch(headless=True)
page = browser.new_page()
page.goto("https://target-site.com")
print(page.content()[:1000])
browser.close()
PY
```

### Persistent profile (cookies survive across runs)

Use `launch_persistent_context()` when you need login state to survive. `launch()` does NOT accept `user_data_dir`.

```bash
/usr/bin/python3 <<'PY'
from cloakbrowser import launch_persistent_context

context = launch_persistent_context(
    user_data_dir="/path/to/profile",
    headless=True,
    humanize=False,
    locale="id-ID",
    viewport={"width": 1366, "height": 768},
    args=["--no-sandbox", "--disable-dev-shm-usage"],
)
page = context.pages[0] if context.pages else context.new_page()
page.goto("https://target-site.com")
# ... do work ...
context.close()
PY
```

**Key difference:** `launch()` → `browser.close()` (session-only). `launch_persistent_context()` → `context.close()` (profile persists).

## Features

- `headless=True` — stealth headless (navigator.webdriver=false)
- `headless=False` — headed mode for sites that detect headless
- `humanize=True` — Bézier mouse curves, per-character typing, human scroll
- `proxy="http://user:pass@host:port"` — HTTP/SOCKS5 proxy
- `geoip=True` — auto timezone/locale from proxy IP (needs `pip install cloakbrowser[geoip]`)

## Anti-Detection Results

| Check | Stock Playwright | CloakBrowser |
|-------|-----------------|--------------|
| navigator.webdriver | true | **false** |
| reCAPTCHA v3 | 0.1 (bot) | **0.9 (human)** |
| Cloudflare Turnstile (non-interactive) | FAIL | **PASS (humanize=True)*** |
| Cloudflare checkbox/managed challenge | FAIL | **FAIL — manual solve required** |
| FingerprintJS | DETECTED | **PASS** |
| BrowserScan | DETECTED | **NORMAL** |

**Cloudflare challenge types:** CloakBrowser passes non-interactive Turnstile challenges via JS fingerprint evasion. However, **checkbox challenges** ("Verify you are human") and **managed challenges** that require clicking a checkbox **cannot** be bypassed automatically — even with `humanize=True`. These require manual human intervention. If the VPS has no display server (no X), you'll need Xvfb + VNC for manual solving, or use a different approach (e.g., ask user to solve in their local browser).

## VPS Notes

- RAM usage: ~300-400MB per browser instance (VPS has 3.6GB — ok for 1-2 concurrent)
- Binary at `~/.cache/ms-playwright/chromium-1223/chrome-linux64/chrome` (377MB, Chromium 146)
- Binary auto-updates on `pip install -U cloakbrowser`
- Works fully headless on VPS (no display needed)
- Playwright API compatible — `page.goto()`, `page.evaluate()`, `page.screenshot()`, etc.
- **Verified VPS results:** see `references/verified-results-vps.md` for live reCAPTCHA/Turnstile/sannysoft scores from this environment
- **Cloudflare challenge types & diagnostic:** see `references/cloudflare-challenge-diagnostic.md` — which challenges CloakBrowser can/can't bypass, diagnostic script, cleanup commands, and reproduction recipes
- **Open mirrors (no CF challenge):** see `references/layarasia-dramastream-mirror.md` — LayarAsia is a dramastream WordPress mirror with CF proxy-only (no challenge wall); scrapeable with plain curl/Python. Structure, extraction regex, ouo.io shortlink resolution strategy, and host/quality mapping documented.

## SPA / JS-Heavy Site Patterns

CloakBrowser drives real Chromium (Playwright API), so JS executes fully. But SPA click interactions need specific approaches because DOM elements re-render dynamically.

### Click reliability: prefer JS dispatch over coordinates

Coordinates (mouse.click) fail when layout shifts. JS event dispatch is more reliable:

```python
# BEST: find by text content, dispatch click
page.evaluate("""() => {
    document.querySelectorAll("*").forEach(el => {
        if (el.innerText && el.innerText.includes("BUTTON TEXT") && el.offsetHeight > 10) {
            el.dispatchEvent(new MouseEvent("click", {bubbles: true, cancelable: true}));
        }
    });
}""")

# ALSO WORKS: native click() (fires onClick handler)
page.evaluate('() => { document.querySelectorAll("button").forEach(b => { if (b.innerText.trim() === "Cari") b.click(); }); }')
```

### Search + select from results

Type into an input, trigger search, then click a result item by matching text:

```python
page.evaluate('() => { document.getElementById("searchQuery").value = ""; document.getElementById("searchQuery").focus(); }')
page.keyboard.type("Cars", delay=15)  # delay=15ms simulates human typing
time.sleep(0.5)
page.evaluate('() => { document.querySelectorAll("button").forEach(b => { if (b.innerText.trim() === "Cari") b.click(); }); }')
time.sleep(2)
# Find result by unique text (e.g. "ID 920") and click
page.evaluate("""() => {
    document.querySelectorAll("*").forEach(el => {
        if (el.innerText && el.innerText.includes("ID 920") && el.offsetHeight > 20) {
            el.dispatchEvent(new MouseEvent("click", {bubbles: true}));
        }
    });
}""")
```

### Debugging a click that "didn't work"

Use `page.evaluate()` to dump element state BEFORE clicking:

```python
info = page.evaluate("""() => {
    const btns = document.querySelectorAll("button");
    return Array.from(btns).filter(b => b.innerText.includes("TARGET")).map(b => ({
        text: b.innerText.trim().substring(0, 50),
        tag: b.tagName, id: b.id,
        className: b.className?.substring(0, 80),
        visible: b.offsetParent !== null,
        rect: b.getBoundingClientRect()
    }));
}""")
print(json.dumps(info, indent=2, default=str))
```

### Canvas-to-file pattern

When a site renders images to `<canvas>`, bypass the download button entirely:

```python
canvas_data = page.evaluate('() => { const c = document.getElementById("previewCanvas"); return c ? c.toDataURL("image/jpeg", 0.95) : null; }')
if canvas_data:
    with open("/tmp/poster.jpg", "wb") as f:
        f.write(base64.b64decode(canvas_data.split(",")[1]))
```

### Scrolling to sections

```python
# By known text anchor
page.evaluate("""() => {
    document.querySelectorAll("*").forEach(el => {
        if ((el.innerText||"").trim() === "GENERATOR JUDUL") {
            el.scrollIntoView({block: "center"});
        }
    });
}""")

# By absolute position
page.evaluate("window.scrollTo(0, 2500)")
```

## Resolving ouo.io Shortlinks

Many drakor sites use `ouo.io` shortlinks before the real download host. Resolution requires 2-step CloakBrowser interaction:

**Step 1:** Load ouo.io page, click "I'M A HUMAN" button → redirects to `/go/` intermediate page.
**Step 2:** `/go/` page has a countdown (~5-10s) then auto-redirects to destination. If auto-redirect doesn't fire, extract from meta refresh or JS:
```python
page.goto(ouo_url, wait_until="load", timeout=15000)
time.sleep(2)
page.evaluate("""() => {
    const all = document.querySelectorAll('*');
    for (const el of all) {
        if (el.innerText && el.innerText.trim().toUpperCase() === "I'M A HUMAN") {
            el.click(); return 'clicked';
        }
    }
    return 'not found';
}""")

# Poll /go/ page for redirect (up to 30s)
for i in range(15):
    time.sleep(2)
    if "ouo.io/go/" not in page.url:
        break  # redirected!
    # Extract from meta refresh as fallback
    redirect = page.evaluate("""() => {
        const meta = document.querySelector('meta[http-equiv="refresh"]');
        if (meta) {
            const m = meta.getAttribute('content').match(/url=(.+)/i);
            if (m) return m[1];
        }
        const links = document.querySelectorAll('a');
        for (const a of links) {
            if (/buzzheavier|akirabox|gofile|terabox/i.test(a.href)) return a.href;
        }
        return null;
    }""")
    if redirect:
        page.goto(redirect, wait_until="load", timeout=15000)
        break
```

**Prefer direct-host links over ouo.io.** Sites like layar.asia serve both — use Terabox/FileMoon/Filekeeper (direct) before attempting ouo.io resolution.

## Quick Usage — Persistent Profile (cookies survive restarts)

If you need saved logins/cookies across sessions, use `launch_persistent_context` (NOT `launch` — `launch()` does not accept `user_data_dir`):

```bash
/usr/bin/python3 <<'PY'
from cloakbrowser import launch_persistent_context

context = launch_persistent_context(
    user_data_dir="/path/to/profile",
    headless=True,
    humanize=False,
    locale="id-ID",
    timezone="Asia/Jakarta",
    viewport={"width": 1366, "height": 768},
    args=["--no-sandbox", "--disable-dev-shm-usage"],
)
page = context.new_page()
page.goto("https://seller.shopee.co.id/", wait_until="domcontentloaded", timeout=30000)
print(page.url)
context.close()
PY
```

## Pitfalls

- **`launch()` does NOT accept `user_data_dir`.** Use `launch_persistent_context()` for persistent profiles (saved cookies/logins). `launch()` starts fresh every time — no cookies survive. Error: `TypeError: BrowserType.launch() got an unexpected keyword argument 'user_data_dir'`.
- **`humanize=True` + `wait_until="networkidle"` = TIMEOUT on slow connections.** The human-like delays (Bézier curves, per-char typing) compound with network latency and `networkidle` never fires within the default 30s. Fix: either (a) drop `wait_until` to `"load"` or `"domcontentloaded"`, (b) don't use `humanize=True` for bulk page navigation, or (c) increase timeout. Use `humanize=True` only for sites that actually need behavioral stealth — it's overkill for standard browsing.
- **`wait_until="domcontentloaded"` hangs forever on Cloudflare challenge pages.** When Cloudflare injects a Turnstile/checkbox challenge, the DOMContentLoaded event never fires because the challenge replaces the original page load lifecycle. The `goto()` call blocks indefinitely until timeout. Fix: use `wait_until="commit"` (returns after HTTP response headers — the earliest practical signal) or `wait_until="load"` with a short timeout (10s), then manually poll `page.title()` or `document.querySelectorAll('a').length` in a loop until the real page content appears.
- **Don't iterate N scripts into a CF checkbox wall.** The escalation ladder is in `references/cloudflare-challenge-diagnostic.md`. When you hit a checkbox challenge: try L1-L2 exactly once each, maybe L3 JS click once as a Hail Mary — then **pivot to fallback sources immediately**. Iterating 5+ scripts with minor variations on the same unwinnable challenge burns time and frustrates users. The diagnostic curl pre-flight tells you the challenge type before you even launch the browser — use it.
- **Chromium processes accumulate across failed runs.** If a script times out or crashes, orphaned `chrome`/`chromium` processes keep consuming ~300MB RAM each. Before retrying after a failure, run: `killall -9 chromium chrome 2>/dev/null; sleep 1; rm -rf /tmp/playwright_chromiumdev_profile-*`. Check with `ps aux | grep -i "chrom\|cloak" | grep -v grep | wc -l` — if >5, clean up.
- **Use system Python, not Hermes venv.** `pip install cloakbrowser` goes to `~/.local/lib/python3.10/site-packages/` (user site). The Hermes venv at `~/.hermes/hermes-agent/venv/` has no `pip`. Always invoke CloakBrowser scripts with `/usr/bin/python3`, not bare `python3`.
- **Do NOT use `browser_navigate` / `browser_click` Hermes tools with CloakBrowser.** CloakBrowser is a Playwright wrapper, not a CDP endpoint. All interaction goes through `terminal()` with Python heredoc scripts.
- **Don't ship raw API keys in output.** Refer to env vars only.
- **Shell heredoc unsafe chars.** Python heredocs containing `&` trigger shell backgrounding and fail with exit code -1. Write multi-line Python scripts to a `.py` file via `write_file`, then execute with `/usr/bin/python3 <script>.py`. Always lint with `write_file` before executing.
- **Clipboard-dependent "Copy" buttons.** Sites that use `navigator.clipboard.writeText()` won't persist copied text in the DOM. After clicking Copy, grab the textarea value directly: `page.evaluate('() => document.querySelector("textarea").value')`.
- **Timeouts on slow sites.** Server response times vary. Generous sleeps (3-8s after generate/upload actions, 2-3s after search/select) prevent racing. Prefer `time.sleep(N)` over `wait_for_timeout` for clarity.
- **Embedded third-party players (TikTok/YouTube).** Download from embedded video platforms is unreliable via DOM interaction — the download button may trigger in-app logic hidden from Playwright. If download fails after clicks, accept the limitation and deliver other assets (poster, text) directly.
