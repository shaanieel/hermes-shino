# layar.asia / dramastream Sites

Family of drakor sites using WordPress + dramastream theme + Cloudflare proxy.

## Detection

These sites share this structure:
- WordPress REST API at `/wp-json/wp/v2/posts`
- Cloudflare proxy but **no challenge** (HTTP 200 directly)
- Theme CSS references `dramastream`
- Download blocks in `<div class="soraddlx">`

## Known instances

| Site | CF Challenge | Status |
|------|-------------|--------|
| server-1.layar.asia | No (proxy only) | ✅ Scrapable |
| dramaday.me | Checkbox challenge | ❌ Needs manual solve |

## Scraping Pattern

### 1. Get post list from WP API
```bash
curl -sI 'https://server-1.layar.asia/wp-json/wp/v2/posts?per_page=1' | grep x-wp-total
# → 5954 posts
```

### 2. Extract download links from HTML
Regex pattern (Python):
```python
sections = re.findall(r'<strong>([^<]+)</strong>(.*?)(?=<strong>|</div>\s*</div>\s*</div>)', html, re.DOTALL)
for quality, section in sections:
    for url, host in re.findall(r'<a[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>', section):
        # host: Terabox, BuzzHeavier, FileMoon, Gofile, Akirabox, etc.
```

### 3. Link Types

**Direct links (no redirect needed):**
- Terabox (1024terabox.com)
- FileMoon (bysezoxexe.com, bysetayico.com)
- Filekeeper (filekeeper.net)
- Upfiles, Krakenfiles, Vikingfile

**ouo.io shortlinks (need CloakBrowser resolution):**
- BuzzHeavier → ouo.io → buzzheavier.com
- Gofile → ouo.io → gofile.io
- Akirabox → ouo.io → akirabox.com

### 4. Stats (as of 2026-06-01)

- 5,954 posts total
- 5,916 with download links
- 44,103 total links
- 1,736 posts with 1080p quality
- ~1,262 posts with 1080p + direct links

Top hosts: Terabox (11,698), FileMoon (5,981), Gofile (5,980), BuzzHeavier (5,787), Filekeeper (5,082)
