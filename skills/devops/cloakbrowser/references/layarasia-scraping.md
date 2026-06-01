# LayarAsia — Open Drakor Mirror (No CF Challenge)

**URL:** `https://server-1.layar.asia/`

**Verdict (2026-06-01):** Cloudflare proxy-only — **no challenge wall**. Fully scrapeable via curl/Python without CloakBrowser. Same `dramastream` WordPress theme as dramaday, but CF protection level is minimal.

## Pre-flight

```bash
curl -sI 'https://server-1.layar.asia/' \
  -H 'User-Agent: Mozilla/5.0 ... Chrome/146...'
# Returns: HTTP/2 200
# No cf-mitigated: challenge header
```

## Site Structure

- **Platform:** WordPress 6.9.4 with `dramastream` theme + `dramastream-child`
- **REST API:** `https://server-1.layar.asia/wp-json/wp/v2/posts`
- **Total posts:** ~5,954 (as of 2026-06-01)
- **Cache:** LiteSpeed Cache (HTML served pre-rendered — no JS needed)

## Download Link Structure

Each post (episode) contains download links in this HTML structure:

```html
<div class="soraddlx">
  <div class="sorattlx"><h3>Episode N</h3></div>
  <div class="soraurlx">
    <strong>360p</strong>
    <a href="https://ouo.io/eVSjxhf">BuzzHeavier</a>
    <a href="https://1024terabox.com/s/...">Terabox</a>
    <a href="https://ouo.io/...">Gofile</a>
    <a href="https://ouo.io/...">Akirabox</a>
    <a href="https://www.mirrored.to/...">Mirrored</a>
  </div>
  <div class="soraurlx">
    <strong>720p</strong>
    ...
  </div>
</div>
```

**Key extraction regex:**
- Blocks: `<div class="soraddlx">(.*?)</div>\s*</div>\s*</div>`
- Rows per block: `<div class="soraurlx">(.*?)</div>`
- Quality: `<strong>(.*?)</strong>`
- Links: `<a[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>`

## Link Resolution

Almost all links use **ouo.io shortlinks**. Must resolve to real URL:

```python
# HEAD first (lighter), fallback to GET
r = session.head(ouo_url, allow_redirects=True, timeout=10,
    headers={"Referer": "https://server-1.layar.asia/"})
if r.url != ouo_url and 'ouo.io' not in r.url:
    return r.url  # resolved
# If HEAD doesn't follow, try GET
r = session.get(ouo_url, allow_redirects=True, timeout=15,
    headers={"Referer": "https://server-1.layar.asia/"})
return r.url  # may still be ouo.io if blocked
```

## Hosts Available

| Host | Link Type | Notes |
|------|-----------|-------|
| BuzzHeavier | ouo.io shortlink | Most common |
| Akirabox | ouo.io shortlink | |
| Terabox | Direct URL | `1024terabox.com/s/...` |
| Gofile | ouo.io shortlink | |
| Mirrored | Direct URL | `www.mirrored.to/files/...` |

## Quality Levels

360p, 480p, 540p, 720p (no 1080p observed in sample)

## Scraping Strategy

1. Paginate REST API: `?per_page=50&page=N&_fields=id,slug,link,title`
2. Fetch each post HTML (server-rendered, no JS needed)
3. Extract `soraddlx` blocks → quality + host + shortlink
4. Resolve ouo.io → real URL
5. No CloakBrowser needed — plain `requests` is sufficient
