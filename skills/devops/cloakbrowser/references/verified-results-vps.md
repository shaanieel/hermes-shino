# Verified Anti-Detection Results

Live test results from this VPS (Ubuntu, headless, no residential proxy).

## reCAPTCHA v3

- **Test site:** https://antcpt.com/score_detector/
- **Date verified:** 2026-05-31
- **Score:** 0.9 (human)
- **User Agent:** Chrome 146.0.0.0 for Windows
- **IP:** 43.156.137.157
- **Google verdict:** "This is a good result, you can work with fast reCAPTCHA 2"
- **Mode:** `launch(headless=True)` — NO humanize needed

## Cloudflare Turnstile

- **Test site:** https://nopecha.com/demo/cloudflare
- **headless=True:** Gets "Performing security verification" challenge (Ray ID), blocked
- **Expected fix:** `headless=false` or `humanize=True` — behavior may vary by site

## bot.sannysoft.com (headless)

| Test | Result |
|------|--------|
| WebDriver | passed |
| WebDriver Advanced | passed |
| Chrome Object | passed |
| Selenium Driver | passed |
| Phantom UA | passed |
| Headless Chrome UA | FAIL (UA string contains "HeadlessChrome") |
| Memory Info | FAIL (navigator.deviceMemory missing) |
| WebGL | FAIL (no GPU on VPS) |

Note: HeadlessChrome in UA is cosmetic — reCAPTCHA still gives 0.9 because other signals (WebDriver=false, plugins, etc.) dominate.

## Browser Tiers (this VPS)

| Tier | Tool | Stealth | Integration |
|------|------|---------|-------------|
| 1 | CDP port 9222 | Basic (UA leaks) | `browser_navigate` direct |
| 2 | CloakBrowser | High (reCAPTCHA 0.9) | `terminal` Python scripts |
| 3 | Browserbase | Premium | Cloud proxy/CAPTCHA auto-solve |
