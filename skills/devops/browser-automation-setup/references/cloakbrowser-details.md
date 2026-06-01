# CloakBrowser — Deep-Dive

Source: https://github.com/CloakHQ/CloakBrowser (22.7k ★, MIT, active)

## What It Is

A custom-compiled Chromium binary with 58 source-level C++ patches that modify fingerprints at the binary level. NOT a JS injection, NOT config flags — the binary itself reports like a real human browser.

## Install

```bash
# Python
pip install cloakbrowser

# Node.js (Playwright)
npm install cloakbrowser playwright-core

# Node.js (Puppeteer)
npm install cloakbrowser puppeteer-core

# Optional: geoip auto-detection
pip install cloakbrowser[geoip]

# Docker test (no install)
docker run --rm cloakhq/cloakbrowser cloaktest
```

Binary auto-downloads on first launch (~200MB, cached).

## Key Flags

- `humanize=True` — Bézier curve mouse, per-char typing, natural scroll
- `geoip=True` — auto-detect timezone/locale from proxy IP
- `proxy="http://user:pass@host:port"` — HTTP proxy
- `proxy="socks5://user:pass@host:port"` — SOCKS5 proxy
- `headless=False` — some sites detect headless even with patches
- `args=["--fingerprint-webrtc-ip=auto"]` — WebRTC IP spoofing

## Test Results (vs detection services)

| Service | Stock Playwright | CloakBrowser |
|---------|-----------------|-------------|
| reCAPTCHA v3 | 0.1 (bot) | **0.9 (human)** |
| Cloudflare Turnstile (non-interactive) | FAIL | **PASS** |
| Cloudflare Turnstile (managed) | FAIL | **PASS** |
| ShieldSquare | BLOCKED | **PASS** |
| FingerprintJS | DETECTED | **PASS** |
| BrowserScan | DETECTED | **NORMAL (4/4)** |
| bot.incolumitas.com | 13 fails | **1 fail** |
| deviceandbrowserinfo.com | 6 true flags | **0 true flags** |
| navigator.webdriver | true | **false** |
| navigator.plugins.length | 0 | **5** |
| window.chrome | undefined | **object** |
| CDP detection | Detected | **Not detected** |
| TLS fingerprint (ja3n/ja4) | Mismatch | **Identical to Chrome** |

## Hermes Integration Pattern

CloakBrowser is NOT a CDP endpoint — it's a Playwright wrapper. Cannot use with `browser_navigate` directly. Use `terminal`:

```bash
terminal(command="/usr/bin/python3 <<'PY'
from cloakbrowser import launch
b = launch(headless=True)
p = b.new_page()
p.goto('URL_HERE', timeout=20000, wait_until='domcontentloaded')
print(p.content()[:3000])
b.close()
PY
", timeout=60)
```

**Pitfalls:**
- Use `/usr/bin/python3` (system Python) — Hermes venv has no `pip`, `pip install cloakbrowser` goes to user site
- `humanize=True` + `wait_until='networkidle'` = timeout on slow VPS connections. Use `wait_until='domcontentloaded'` or `'load'`, and only enable `humanize=True` for sites needing behavioral stealth
- For persistent sessions across multiple terminal calls, use `launch_persistent_context()`
- **`launch_persistent_context()` hangs silently if another Chromium process is already using the same `user_data_dir`.** The profile directory is locked by the first instance; the second one blocks forever without an error. On this VPS, the `shaa-browser` service runs its own CloakBrowser on the same profile. Before launching a new persistent context, kill the existing process using that profile (`pgrep -f "user-data-dir"` + `kill`), or use a separate profile directory.

## Current Version

v0.3.31 (Chromium 146, 22.7k ★ GitHub, MIT) — tested on Ubuntu VPS, headless mode verified.
