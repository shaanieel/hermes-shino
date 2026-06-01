# Hermes VPS CDP Browser Setup

How to wire Hermes built-in browser tools (`browser_navigate`, `browser_click`, etc.) to a headless Chromium on a VPS — reusing the Playwright/CloakBrowser binary as a CDP endpoint.

## Prerequisites

- CloakBrowser installed (`pip install cloakbrowser`), which downloads Chromium to `~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`
- Browser Harness cloned to `~/Developer/browser-harness` (optional but useful for testing)

## Step 1: Launch Chromium with fixed debug port

The CloakBrowser Playwright Chromium binary works as a standalone CDP endpoint:

```bash
# Launch as background process (cannot use systemd user mode — GROUP/216 error on this VPS)
CHROME_BIN="$HOME/.cache/ms-playwright/chromium-1223/chrome-linux64/chrome"
USER_DATA="$HOME/.cache/browser-harness-chrome"
mkdir -p "$USER_DATA"

$CHROME_BIN \
  --headless=new \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --remote-debugging-port=9222 \
  --user-data-dir="$USER_DATA" \
  --window-size=1280,720 &
```

Verify: `ss -tlnp | grep 9222` — should show `LISTEN 127.0.0.1:9222`.

**Note:** systemd user mode (`systemctl --user`) fails with `status=216/GROUP` for Chromium on this VPS. Chromium must be launched directly or via Hermes `terminal(background=true)`.

## Step 2: Set CDP URL in Hermes config

Use `hermes config set` (do NOT edit `~/.hermes/config.yaml` directly — it's protected):

```bash
hermes config set browser.cdp_url http://127.0.0.1:9222
```

This sets `browser.cdp_url` in `~/.hermes/config.yaml`, which `browser_navigate` reads at startup. The config key takes precedence over env var `BROWSER_CDP_URL` — both work but config.yaml is persistent.

## Step 3: Verify

```bash
# Via browser-harness CLI (quick check)
BU_CDP_URL=http://127.0.0.1:9222 browser-harness <<'PY'
new_tab("https://httpbin.org/headers")
wait_for_load()
print(page_info())
PY

# Via Hermes built-in tools — after config set, browser_navigate should work immediately
```

## Pitfalls

- **Do NOT hijack existing Chromium processes.** On this VPS, WAHA Docker runs its own Chromium with `--remote-debugging-port=0` (random port). Always launch a separate instance with fixed port 9222.
- **Do NOT use `hermes config set` while gateway is mid-turn.** The `cdp_url` is read at tool invocation time, so no restart needed in practice.
- **Port conflict:** if 9222 is taken, pick another port and update both the launch command and config.
- **The binary path includes a version number** (`chromium-1223`). It changes when CloakBrowser updates. Use `ls ~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome` to find the current one.
- **RAM:** ~300-400MB per Chromium instance. This VPS has ~3.6GB — budget accordingly when running alongside other services.
- **`browser_navigate` may return an empty snapshot (`"(empty page)"`) on JS-heavy pages** like Shopee login (SPA redirects). The HTML loads but the accessibility tree hasn't populated yet. Retry with `browser_snapshot(full=true)` after navigation — the snapshot almost always populates on the second attempt. Do NOT assume the page failed to load.
