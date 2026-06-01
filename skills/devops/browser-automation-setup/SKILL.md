---
name: browser-automation-setup
description: Set up and troubleshoot browser automation harnesses for Hermes/Codex, including Browser Harness, CDP/remote-debugging, and cloud browser options.
---

# Browser Automation Setup

Use this when the user asks to install, connect, or troubleshoot browser automation tools such as `browser-use/browser-harness`, CDP-based Chrome control, or cloud browsers.

## Workflow

1. **Read upstream install docs first.** Browser harnesses have connection-specific requirements; inspect `README.md` and install docs before guessing commands.
2. **Install into a durable checkout.** Prefer a stable path such as `~/Developer/<tool>` rather than `/tmp`, then install editable if upstream recommends it.
3. **Expose the agent skill.** If the tool ships a `SKILL.md`, symlink it into the active agent skill directories when appropriate, e.g. `~/.codex/skills/...` and `~/.hermes/skills/...`.
4. **Run the tool's doctor/check command.** Report install state separately from browser connection state.
5. **Separate install from connection.** A CLI can be installed while no browser is attached; do not call the whole setup failed just because CDP/daemon is not connected.
6. **Offer connection paths.** Explain local Chrome remote debugging, isolated Chrome with `--remote-debugging-port`, and cloud browser/API-key options.

## Browser Harness Pattern

For `https://github.com/browser-use/browser-harness`:

```bash
mkdir -p ~/Developer
git clone https://github.com/browser-use/browser-harness ~/Developer/browser-harness
cd ~/Developer/browser-harness
uv tool install -e .
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/browser-harness"
ln -sf "$PWD/SKILL.md" "${CODEX_HOME:-$HOME/.codex}/skills/browser-harness/SKILL.md"
mkdir -p "$HOME/.hermes/skills/browser-harness"
ln -sf "$PWD/SKILL.md" "$HOME/.hermes/skills/browser-harness/SKILL.md"
browser-harness --doctor
```

A good partial result is: executable installed, skill visible, doctor runs. Connection may still require user/browser action.

## Connection Options

- **Real local browser:** open `chrome://inspect/#remote-debugging`, tick `Allow remote debugging for this browser instance`, and click any Chrome attach approval popup.
- **Isolated browser:** launch Chrome/Chromium with `--remote-debugging-port=9222 --user-data-dir=<non-default-dir>`, then use `BU_CDP_URL=http://127.0.0.1:9222`.
- **Cloud browser:** set `BROWSER_USE_API_KEY` and follow the tool's cloud-browser flow; use this for headless/unattended/proxy/captcha-heavy work when the user opts in.

## Stealth Browser Option: CloakBrowser

When the user needs a browser that passes anti-bot detection (Cloudflare, reCAPTCHA, FingerprintJS), **CloakBrowser** (`https://github.com/CloakHQ/CloakBrowser`) is the best free/open-source option — it patches Chromium at the C++ source level (58 patches), not via JS injection or config hacks. 22.7k stars, MIT license.

Quick comparison of the three browser options:

| Option | Stealth | Integration | Use case |
|--------|---------|-------------|----------|
| Hermes built-in browser | None (webdriver=true) | Direct `browser_navigate` etc. | Casual browsing, non-protected sites |
| Browser Harness + Browserbase cloud | Residential proxy, some stealth | `browser-harness` CLI | Sites with moderate anti-bot |
| CloakBrowser | 58 C++ patches, reCAPTCHA 0.9, passes Turnstile | Via `terminal` (Playwright API) | Sites with strict anti-bot |

CloakBrowser's key stats: reCAPTCHA v3 score 0.9 (human), Cloudflare Turnstile auto-resolve, `navigator.webdriver=false`, passes FingerprintJS + BrowserScan.

**Install:**

```bash
pip install cloakbrowser
# or: npm install cloakbrowser playwright-core
```

**Caveat for Hermes integration:** CloakBrowser is a Playwright/Puppeteer wrapper, NOT a CDP endpoint. It cannot be used with Hermes's built-in `browser_navigate` / `browser_click` tools directly. Use it via `terminal` with Python/Node scripts. Example:

```bash
terminal(command="/usr/bin/python3 <<'PY'
from cloakbrowser import launch
b = launch(headless=True)
p = b.new_page()
p.goto('https://target-site.com', timeout=20000, wait_until='domcontentloaded')
print(p.content()[:2000])
b.close()
PY
", timeout=60)
```

**VPS install notes (Ubuntu):**

```bash
# Install (uses system Python, not Hermes venv)
pip install cloakbrowser
pip install "cloakbrowser[geoip]"  # optional: auto timezone from proxy IP

# Binary auto-downloads on first launch (~377MB, ~/.cache/ms-playwright/)
# Check: /usr/bin/python3 -c "from cloakbrowser import launch; launch(headless=True).close()"
```

**Pitfalls specific to CloakBrowser on VPS:**
- `humanize=True` + `wait_until="networkidle"` → timeout on slow VPS connections. Use `wait_until="domcontentloaded"` or `wait_until="load"`, and only enable `humanize=True` for sites that need behavioral stealth.
- Always use `/usr/bin/python3` (system Python) — Hermes venv has no `pip` so `pip install` goes to user site, and bare `python3` may resolve to the venv.
- Browserbase cloud browser has a free tier: **10 tasks/month, 3 concurrent sessions, advanced stealth, residential proxies included**. Great for occasional use — tell the user they can try it for free.

When the user asks about "stealth browser" or "anti-detect browser" or "CloakBrowser", load this skill and present all three options with tradeoffs.

## Pitfalls

- Do not paste browser cloud API keys or service credentials in final replies; refer to env var names only.
- Do not capture a transient missing-browser or missing-binary state as a durable limitation. Capture the connection fix instead.
- Browser automation is heavier than text-only tools; warn VPS users about RAM/CPU impact when launching full Chromium.

## References

- `references/browser-harness-install.md` captures the Browser Harness install and connection-check pattern.
- `references/cloakbrowser-details.md` — CloakBrowser deep-dive: test results, install, API flags, Hermes integration pattern.
- `references/vps-chromium-cdp.md` — launching headless Chromium on VPS with CDP port, connecting to Hermes browser tools.
- `references/hermes-vps-cdp-setup.md` — Wire Hermes `browser_navigate` to a headless Chromium CDP endpoint on a VPS (reuses Playwright/CloakBrowser binary, port 9222, `hermes config set browser.cdp_url`).
