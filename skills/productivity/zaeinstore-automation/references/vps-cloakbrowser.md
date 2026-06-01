# VPS CloakBrowser Setup

## Install

```bash
# Use system python3, NOT Hermes venv
/usr/bin/pip3 install cloakbrowser
```

Binary location: `~/.cache/ms-playwright/` (~377MB Chromium 146)

## Known Quirks

- `humanize=True` + `networkidle` = timeout on VPS. Use `domcontentloaded` instead.
- `webdriver=false` and geoip installed by default on this VPS.
- Download path: use `/tmp/cloakbrowser-downloads/` (must pre-create with `os.makedirs`).
- CloakBrowser's `Page` object has no `_client` attribute — cannot use CDP directly. Use `p.evaluate()` for JS injection.

## Quick Reference

```python
from cloakbrowser import launch
b = launch(headless=True)
p = b.new_page()
p.set_viewport_size({"width": 1280, "height": 900})
p.goto("https://example.com", timeout=20000, wait_until="domcontentloaded")
```

## Cleanup

Temporary scripts live in `/tmp/cloak_*.py`. Clean up periodically:

```bash
rm -f /tmp/cloak_*.py /tmp/zaein_*.py /tmp/vid_*.py
```
