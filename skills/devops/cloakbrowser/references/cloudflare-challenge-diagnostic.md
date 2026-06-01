# Cloudflare Challenge Diagnostic

When CloakBrowser hits a 403 / Cloudflare challenge page, use this script to diagnose the challenge type and determine next steps.

## Quick Diagnostic Script

```python
"""
Diagnose Cloudflare challenge type on any URL
"""
from cloakbrowser import launch
import time

URL = "https://TARGET-URL-HERE"

browser = launch(headless=True)
page = browser.new_page()

# Use 'commit' — it returns after HTTP response, doesn't wait for DOM
try:
    page.goto(URL, wait_until="commit", timeout=15000)
    print("commit OK")
except Exception as e:
    print(f"commit failed: {e}")
    browser.close()
    exit(1)

# Poll for 60 seconds
for i in range(12):
    time.sleep(5)
    title = page.title()
    body_len = page.evaluate("() => document.body.innerText.length")
    anchors = page.evaluate("() => document.querySelectorAll('a').length")

    is_cf = "moment" in title.lower() or "verification" in title.lower()

    print(f"[{i*5}s] title='{title}' bodyLen={body_len} anchors={anchors} isCF={is_cf}")

    if not is_cf and anchors > 10:
        print("PASSED — real content loaded")
        break

# Take screenshot for manual inspection
page.screenshot(path="/tmp/cf_diagnostic.png")
print("Screenshot: /tmp/cf_diagnostic.png")

browser.close()
```

## Interpreting Results

| Screenshot shows | Meaning | Action |
|---|---|---|
| "Verify you are human" checkbox | Checkbox/managed challenge | **Manual solve required.** Install Xvfb+VNC or ask user. |
| "Just a moment..." spinner that resolves | Non-interactive Turnstile | Should auto-pass with `humanize=True`. If not, try longer polling. |
| 403 / block page (no challenge UI) | IP/ASN block | Need proxy or different exit node. |
| "Checking your browser..." with JS | JS challenge | Usually auto-pass within 5-15s. Poll longer. |

## Cleanup After Failed Runs

```bash
killall -9 chromium chrome 2>/dev/null
sleep 1
rm -rf /tmp/playwright_chromiumdev_profile-*
rm -rf /tmp/cloak_*
```

## Pre-Flight: Curl Check Before Browser

Before launching CloakBrowser, do a quick `curl -sI -L` to see if the site returns `cf-mitigated: challenge` — this tells you CF protection level instantly without 30+ seconds of browser overhead:

```bash
curl -sI -L --max-time 15 'https://TARGET-URL' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' 2>&1 | grep -i 'cf-mitigated\|http/'
```

If you see `cf-mitigated: challenge` → the site uses Cloudflare challenge. If you also see `HTTP/2 403` → aggressive protection. Use this to decide: CloakBrowser is worth trying, but set expectations correctly.

## Escalation Ladder

When CloakBrowser hits a Cloudflare wall, follow this order. **Stop and pivot at the first clear failure — do NOT iterate N scripts into the same wall:**

| Level | Approach | When to stop | Proven result |
|-------|----------|-------------|---------------|
| 1 | `launch(headless=True, humanize=True)` + `wait_until="commit"` + poll 60s | Works for non-interactive Turnstile | ✓ spinners auto-resolve |
| 2 | `humanize=True` + Google referrer (navigate Google first, then target) | Same as L1 — doesn't help checkbox | ✗ no improvement on dramaday |
| 3 | JS click on checkbox: `document.querySelector('input[type="checkbox"]').click()` + poll | **Stop immediately** — CF ignores synthetic clicks; needs real mouse events | ✗ verified 2026-05-31 on dramaday |
| 4 | `headless=False` (headed mode) | **Requires X server** — VPS without display crashes with `Missing X server or $DISPLAY` | N/A on headless VPS |
| **5** | **PIVOT to fallback sources** | After L3 fails, don't waste more scripts | ↓ |

### Fallback Sources (L5)

When CloakBrowser can't bypass the CF checkbox, try these before asking the user to solve manually:

```bash
# Google Cache — works for static sites, fails for SPAs (JS-obfuscated content)
curl -sL 'https://webcache.googleusercontent.com/search?q=cache:TARGET-URL' \
  -H 'User-Agent: Mozilla/5.0'

# Web Archive — often rate-limited (429), worth a quick check
curl -sL 'https://web.archive.org/web/2025/TARGET-URL' \
  --max-time 15

# Google cache with strip (sometimes cleaner output)
curl -sL 'https://webcache.googleusercontent.com/search?strip=1&q=cache:TARGET-URL'
```

**Dramastream mirror sites:** `server-1.layar.asia` is a dramastream-themed WordPress mirror with no Cloudflare challenge (HTTP 200, plain curl OK). Same theme/template as dramaday.me. Many download links use `ouo.io` shortlinks that need JS → use CloakBrowser for those. Terabox/FileMoon links are direct, no CloakBrowser needed. See `references/layarasia-dramastream-mirror.md` for full scraping guide.

**Open mirror discovery:** Many drakor sites share the same `dramastream` WordPress theme. When one mirror has aggressive CF, search for sister sites. Quick pre-flight check:

```bash
curl -sI --max-time 10 'https://MIRROR-URL' \
  -H 'User-Agent: Mozilla/5.0 ... Chrome/146...' | grep -i 'cf-mitigated'
# If NO cf-mitigated header → NO challenge wall → scrapeable with plain curl!
```

**Google Cache result on dramaday.me:** returned 200 with 90KB body but content was JS-obfuscated SPA shell — no real episode data. SPA sites cached by Google typically lose their rendered content. For static/SSR sites, cache can be a goldmine.

## Reproduction: dramaday.me (2026-05-31)

- URL: `https://dramaday.me/my-royal-nemesis/`
- Pre-flight: `HTTP/2 403`, `cf-mitigated: challenge`
- Result: Cloudflare checkbox challenge ("Verify you are human")
- **9 script attempts across ~4 different approaches** — all failed:
  - Approach A: `humanize=True` + `domcontentloaded` → hung forever (DOMContentLoaded never fires on CF)
  - Approach B: `humanize=True` + `commit` + poll 85s → stayed on `Just a moment...` the entire time
  - Approach C: Google referrer (`page.goto("https://google.com")` first, then `window.location.href = target`) → no improvement
  - Approach D: JS click on checkbox: `document.querySelector('input[type="checkbox"]').click()` → CF ignored it; still stuck
  - Approach E: `headless=False` → crashed (no X server on VPS)
  - Fallback: Google Cache → 200 OK but JS-obfuscated SPA shell (no real content)
  - Fallback: Web Archive → 429 rate-limited
  - Fallback: WP REST API / sitemap / feed → all 403
- **Verdict:** This site requires manual human checkbox click. No workaround found.
