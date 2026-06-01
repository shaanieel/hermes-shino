# VPS Headless Chromium for CDP (browser-harness / Hermes browser tools)

## Launch command

```bash
CHROME="/home/ubuntu/.cache/ms-playwright/chromium-1223/chrome-linux64/chrome"
USER_DATA="/home/ubuntu/.cache/browser-harness-chrome"

mkdir -p "$USER_DATA"

$CHROME \
  --headless=new \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --remote-debugging-port=9222 \
  --user-data-dir="$USER_DATA" \
  --window-size=1280,720
```

Launch via Hermes `terminal(background=true)` — Chromium stays alive, exposing CDP on `127.0.0.1:9222`.

## Config

```bash
hermes config set browser.cdp_url http://127.0.0.1:9222
```

Sets `browser.cdp_url` in `~/.hermes/config.yaml`. Hermes browser tools (`browser_navigate`, `browser_click`, etc.) auto-discover CDP endpoint from this config + `BROWSER_CDP_URL` env var.

## Verification

```bash
# Check port
ss -tlnp | grep 9222

# Check CDP version
curl -s http://127.0.0.1:9222/json/version | python3 -c "import sys,json; print(json.load(sys.stdin)['Browser'])"

# Test via browser-harness CLI
cd ~/Developer/browser-harness && BU_CDP_URL=http://127.0.0.1:9222 browser-harness <<'PY'
print(page_info())
PY
```

## Pitfalls

- `--remote-debugging-port=0` means random port — browser-harness can't discover it. Always use fixed port.
- Do NOT reuse WAHA's Chromium (runs as root, random port, managed by Docker).
- Systemd user service (`systemctl --user`) fails with `status=216/GROUP` on this VPS — use manual `terminal(background=true)` instead.
- Chromium binary at `~/.cache/ms-playwright/` — installed by CloakBrowser's pip dep. No separate apt install needed.
