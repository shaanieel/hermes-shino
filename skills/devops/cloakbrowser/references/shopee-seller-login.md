# Shopee Seller Centre Login via CloakBrowser

## Profile path
`/opt/projects/shopee-upload-vps/profiles/shopee`

## Persistent context pattern (cookies survive restarts)

```python
from cloakbrowser import launch_persistent_context

context = launch_persistent_context(
    user_data_dir="/opt/projects/shopee-upload-vps/profiles/shopee",
    headless=True,
    humanize=False,
    locale="id-ID",
    timezone="Asia/Jakarta",
    viewport={"width": 1366, "height": 768},
    args=["--no-sandbox", "--disable-dev-shm-usage", "--lang=id-ID"],
)
page = context.new_page()
page.goto("https://seller.shopee.co.id/", wait_until="domcontentloaded", timeout=30000)
```

## Login status detection

```python
url = page.url
if "login" in url.lower() or "signin" in url.lower():
    print("BELUM LOGIN")
else:
    print("SUDAH LOGIN")
```

## Stack for visual access (VPS with noVNC)

When the user needs a graphical browser reachable via browser:
- `shaa-browser.service`: Xvfb + fluxbox + x11vnc + noVNC + cloudflared tunnel
- Public URL: https://browser.zaeinstream.my.id/vnc.html (Cloudflare Access protected)
- Local: http://localhost:6080/vnc.html
- DISPLAY=:99 (Xvfb 1366x768)

Restart: `sudo systemctl restart shaa-browser`

## Pitfalls

- Cookies expire after ~days/weeks. If redirected to login page, session expired — need re-login.
- Cloudflare Access on public tunnel adds an extra auth step (email OTP) before reaching noVNC.
- `launch()` doesn't support `user_data_dir` — use `launch_persistent_context()`.
