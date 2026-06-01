# LayarAsia — VPS-friendly dramastream mirror

`server-1.layar.asia` is a dramastream-themed WordPress site that does **NOT** enforce Cloudflare checkbox challenges. Accessible from VPS via plain `curl`/`requests` — no CloakBrowser needed unless resolving `ouo.io` shortlinks.

## Pre-flight

```bash
curl -sI --max-time 10 'https://server-1.layar.asia/' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
  2>&1 | grep -i 'http/|cf-mitigated|server|403'
```

Expected: `HTTP/2 200`, `server: cloudflare`, **no** `cf-mitigated: challenge`.

## Site structure

- WordPress 6.9.4 with `dramastream` theme (child: `dramastream-child`)
- WP REST API at `wp-json/wp/v2/posts` (~5954 posts)
- REST API content field is **empty** — download links live in raw HTML post body
- LiteSpeed Cache active

## Download link extraction (regex)

Each post's download links are inside `<div class="soraddlx">` blocks. The effective pattern:

```python
import re, requests

html = requests.get(post_url, headers=headers, timeout=15).text

# Match quality sections: <strong>QUALITY</strong> ... links ... until next <strong> or block end
sections = re.findall(
    r'<strong>([^<]+)</strong>(.*?)(?=<strong>|</div>\s*</div>\s*</div>)',
    html, re.DOTALL
)

for quality, section in sections:
    quality = quality.strip()
    for url, host in re.findall(
        r'<a[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>',
        section
    ):
        host = host.strip()
        # Skip Mirrored — it's a link aggregator, not a download host
        if host.lower() == "mirrored":
            continue
        print(f"[{quality}] {host}: {url}")
```

## Host types and URL format

| Host | URL type | Needs JS resolve? |
|------|----------|-------------------|
| Terabox | `https://1024terabox.com/s/...` | ❌ Direct link |
| FileMoon | `https://bysezoxexe.com/d/...` | ❌ Direct link |
| BuzzHeavier | `https://ouo.io/...` | ✅ ouo.io shortlink |
| Akirabox | `https://ouo.io/...` | ✅ ouo.io shortlink |
| Gofile | `https://ouo.io/...` | ✅ ouo.io shortlink |
| Mirrored | `https://www.mirrored.to/files/...` | ❌ Skip — aggregator |

## ouo.io shortlinks

`ouo.io` shortlinks do **NOT** resolve via HTTP redirects alone (confirmed 2026-06-01). Plain `curl`/`requests.get(allow_redirects=True)` returns the same `ouo.io` URL. Resolution requires JavaScript execution — use CloakBrowser:

```python
from cloakbrowser import launch

browser = launch(headless=True)
page = browser.new_page()
page.goto(ouo_url, wait_until="load", timeout=15000)
time.sleep(2)
real_url = page.url  # e.g. https://buzzheavier.com/...
page.close()
```

For bulk resolution: batch 5-10 links per browser instance, close pages after each.

Use the bundled `scripts/ouo-resolver.py` to resolve ouo.io links:
```bash
# Resolve a list of URLs
/usr/bin/python3 ~/.hermes/skills/devops/cloakbrowser/scripts/ouo-resolver.py \
  "https://ouo.io/abc123" "https://ouo.io/def456"

# Resolve from JSON file (extracts all ouo.io URLs recursively)
/usr/bin/python3 ~/.hermes/skills/devops/cloakbrowser/scripts/ouo-resolver.py \
  /tmp/layarasia_all_links.json
```

## WP REST API vs raw HTML

**REST API gives you:** post ID, slug, title, URL, categories, date
**REST API does NOT give you:** download links (content field is empty)

Strategy: use API for post discovery + metadata, then fetch raw HTML per post for links.

## Usage as dramaday fallback

When dramaday.me blocks with Cloudflare checkbox challenge, check if LayarAsia has the same content:
1. Search LayarAsia by title slug
2. If found, scrape via plain `requests` (no Cloudflare)
3. For `ouo.io` links only: resolve with CloakBrowser
4. Terabox/FileMoon direct links: deliver as-is, no CloakBrowser needed

## Verified: 2026-06-01

- Site: `server-1.layar.asia`
- Status: `HTTP/2 200`, no CF challenge
- Post count: 5954
- Test post: Reborn Rookie Ep 1+2 — 5 qualities each, all hosts present
