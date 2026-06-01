"""
Resolve ouo.io shortlinks to real URLs using CloakBrowser.
Usage: /usr/bin/python3 ouo-resolver.py <ouo_url_or_file>

Input: one or more ouo.io URLs (stdin, args, or JSON file)
Output: JSON mapping shortlink → real URL
"""
from cloakbrowser import launch
import time, sys, json, re

def resolve_batch(urls, max_concurrent=5):
    """
    Resolve a list of ouo.io URLs.
    Returns dict: {shortlink: real_url}
    """
    browser = launch(headless=True)
    resolved = {}
    
    for i, url in enumerate(urls):
        try:
            page = browser.new_page()
            page.goto(url, wait_until="load", timeout=15000)
            time.sleep(2)
            resolved[url] = page.url
            page.close()
        except Exception as e:
            resolved[url] = f"ERROR: {e}"
        
        if (i + 1) % 10 == 0:
            print(f"  {i+1}/{len(urls)} resolved", file=sys.stderr, flush=True)
    
    browser.close()
    return resolved

def main():
    urls = []
    
    # Accept URLs from command line args
    for arg in sys.argv[1:]:
        if arg.startswith("http"):
            urls.append(arg)
        elif arg.endswith(".json"):
            with open(arg) as f:
                data = json.load(f)
            # Flatten nested structures
            if isinstance(data, list):
                for item in data:
                    urls.extend(extract_ouo_urls(item))
            elif isinstance(data, dict):
                urls.extend(extract_ouo_urls(data))
    
    # Accept from stdin
    if not urls and not sys.stdin.isatty():
        text = sys.stdin.read()
        urls = re.findall(r'https?://ouo\.io/\S+', text)
    
    if not urls:
        print("Usage: ouo-resolver.py <url1> <url2> ... or pipe ouo.io URLs via stdin", file=sys.stderr)
        sys.exit(1)
    
    # Deduplicate
    urls = list(dict.fromkeys(urls))
    print(f"Resolving {len(urls)} ouo.io links...", file=sys.stderr, flush=True)
    
    resolved = resolve_batch(urls)
    
    # Output as JSON
    print(json.dumps(resolved, indent=2, ensure_ascii=False))

def extract_ouo_urls(obj):
    """Recursively find all ouo.io URLs in a nested dict/list"""
    urls = []
    if isinstance(obj, dict):
        for v in obj.values():
            urls.extend(extract_ouo_urls(v))
    elif isinstance(obj, list):
        for item in obj:
            urls.extend(extract_ouo_urls(item))
    elif isinstance(obj, str) and "ouo.io" in obj:
        urls.append(obj)
    return urls

if __name__ == "__main__":
    main()
